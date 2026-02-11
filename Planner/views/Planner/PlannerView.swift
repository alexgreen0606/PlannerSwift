//
//  PlannerView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

struct PlannerView: View {
    private let datestamp: String
    private let closePlanner: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext
    @Query private var planners: [Planner]
    @Query private var calendarSettingsList: [CalendarSettings]

    @EnvironmentObject var calendarStore: CalendarStore
    @EnvironmentObject var todaystampManager: TodaystampWatcher
    @ObservedObject var weatherStore = WeatherStore.shared

    @StateObject private var plannerManager = ListManager<PlannerEvent>()
    @State private var calendarEventToggler = CalendarEventToggler()

    @State private var plannerEventSheetContext: EventSheetContext?
    @Namespace private var sheetAnimation

    @State private var calendarPlannerEvents: [PlannerEvent] = []
    @State private var isDeleteCheckedConfirmationOpen = false
    @State private var isLocationSheetOpen = false
    @State private var pendingScroll: PlannerEventPositionChange?

    // Toggle confirmation config for calendar events.
    private var toggleEventIconConfig: CustomIconConfig<PlannerEvent>? {
        switch plannerType {
        case .pastOrPresent: return nil
        case .future:
            return CustomIconConfig(
                name: "circle.slash",
                primaryColor: .red,
                secondaryColor: Color(uiColor: .secondaryLabel),
                confirmation: ConfirmationConfig(
                    title: "Delete from calendar?",
                    message: "Hiding only affects visibility in this planner.",
                    destructiveKeys: ["Delete"],
                    needsConfirmation: { event in
                        event.calendarEvent != nil
                            && !calendarEventToggler.isPlannerEventChecked(
                                event
                            )
                    },
                    actions: [
                        "Hide": { event in
                            let _ = calendarEventToggler.toggleEvent(event)
                        }
                    ],
                    destructiveActions: [
                        "Delete": { event in
                            guard let calEvent = event.calendarEvent else {
                                return
                            }

                            calendarStore.delete(event: calEvent)

                            reloadCalendar()
                        }
                    ]
                )
            )
        }
    }

    // MARK: - Swift Data

    private var calendarSettings: CalendarSettings? {
        calendarSettingsList.first
    }

    private var planner: Planner? {
        planners.first
    }

    // MARK: - Helper Variables

    private var date: Date {
        datestamp.date ?? Date()
    }

    private var plannerType: PlannerType {
        datestamp <= todaystampManager.todaystamp ? .pastOrPresent : .future
    }

    private var showChecked: Bool {
        plannerType == .future
            ? planner?.showCanceled == true : planner?.showCompleted == true
    }

    private var rawCheckedEvents: [PlannerEvent] {
        guard let planner else {
            return []
        }

        let combinedEvents = planner.events + calendarPlannerEvents

        return
            combinedEvents
            .filter {
                calendarEventToggler.isPlannerEventChecked($0)
            }
    }

    // MARK: - UI Lists

    private var sortedOpenPlans: [PlannerEvent] {
        guard let planner else {
            return []
        }

        let combinedEvents = planner.events + calendarPlannerEvents

        return
            combinedEvents
            .filter {
                (!(calendarEventToggler.isPlannerEventChecked($0))
                    && !plannerManager.newlyUncheckedIds.contains($0.id))
                    || plannerManager.newlyCheckedIds.contains($0.id)
            }
            .sorted {
                $0.sortIndex < $1.sortIndex
            }
    }

    private var sortedCheckedPlans: [PlannerEvent] {
        guard let planner else {
            return []
        }

        let combinedEvents = planner.events + calendarPlannerEvents

        return
            combinedEvents
            .filter {
                (calendarEventToggler.isPlannerEventChecked($0)
                    && !plannerManager.newlyCheckedIds.contains($0.id))
                    || plannerManager.newlyUncheckedIds.contains($0.id)
            }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    // Set the query to find this date's planner.
    init(datestamp: String, closePlanner: @escaping () -> Void) {
        self.datestamp = datestamp
        self.closePlanner = closePlanner

        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == datestamp
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                SortableListView<
                    PlannerEvent, AnyView, AnyView, AnyView
                >(
                    uncheckedItems: sortedOpenPlans,
                    checkedItems: sortedCheckedPlans,
                    showChecked: showChecked,
                    floatingInfo: AnyView(
                        Group {
                            if let planner {
                                PlannerChipSpreadView(
                                    planner: planner,
                                    iconMap: calendarSettings?.iconMap ?? [:],
                                    animation: sheetAnimation,
                                    openCalendarEventSheet: { calEvent in
                                        plannerEventSheetContext =
                                            EventSheetContext(
                                                plannerEvent: nil,
                                                calendarEvent: calEvent
                                            )
                                    },
                                    openLocationSheet: {
                                        isLocationSheetOpen = true
                                    }
                                )
                            } else {
                                EmptyView()
                            }
                        }
                    ),
                    customToggleConfig: toggleEventIconConfig,
                    checkedHeader: plannerType.checkedHeader,
                    checkedFooter: plannerType.getCheckedFooter(for: datestamp),
                    emptyUncheckedLabel: "No plans",
                    emptyCheckedLabel: plannerType.emptyCheckedLabel,
                    animation: sheetAnimation,
                    tint: { event in
                        if let calendar = event.calendarEvent?.calendar {
                            return Color(cgColor: calendar.cgColor)
                        }

                        return accentColor.swiftUIColor
                    },
                    toolbarIcons: ["clock"],
                    tapToolbar: { icon, event in
                        plannerEventSheetContext = EventSheetContext(
                            plannerEvent: event,
                            calendarEvent: nil
                        )
                    },
                    startAdornment: { event in
                        if let calendarEvent = event.calendarEvent,
                            let calendar = calendarEvent.calendar
                        {
                            AnyView(
                                Image(
                                    systemName:
                                        calendarSettings?.iconMap[
                                            calendar.calendarIdentifier
                                        ] ?? calendar.iconName
                                )
                                .foregroundStyle(
                                    Color(cgColor: calendar.cgColor)
                                )
                                .padding(.trailing, 6)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    plannerEventSheetContext =
                                        EventSheetContext(
                                            plannerEvent: event,
                                            calendarEvent: nil
                                        )
                                }
                            )
                        } else {
                            AnyView(
                                EmptyView()
                            )
                        }
                    },
                    endAdornment: { event in
                        AnyView(
                            event.timeValueView(
                                for: datestamp,
                                openSheet: { event in
                                    plannerEventSheetContext =
                                        EventSheetContext(
                                            plannerEvent: event,
                                            calendarEvent: nil
                                        )
                                },
                                accentColor: accentColor.swiftUIColor
                            )
                        )
                    },
                    proxy: proxy,
                    createItem: createEvent,
                    handleTitleChange: handleEventTitleChange,
                    moveItem: handleMoveUncheckedEvent,
                    isItemChecked: calendarEventToggler.isPlannerEventChecked
                )
                .navigationTitle(date.dynamicHeader)
                .navigationSubtitle(date.dynamicSubheader)
                .toolbar {
                    topLeftToolbar
                    topRightToolbar
                    bottomToolbar(proxy)
                }

                // Event Sheet
                .sheet(item: $plannerEventSheetContext) { context in
                    EventFormView(
                        plannerEvent: context.plannerEvent,
                        calendarEvent: context.calendarEvent
                    ) { change in
                        pendingScroll = change
                    }
                    .navigationTransition(
                        .zoom(
                            sourceID: context.id,
                            in: sheetAnimation
                        )
                    )
                }

                // Location Sheet
                .sheet(isPresented: $isLocationSheetOpen) {
                    if let planner {
                        LocationSearchView(
                            initialLocation: planner.location,
                            title: "Edit Location",
                            mode: .sheet
                        ) { location in
                            planner.location = location

                            do {
                                try modelContext.save()
                            } catch {
                                assertionFailure(
                                    "Failed to save location: \(error)"
                                )
                            }

                            Task {
                                await weatherStore
                                    .loadWeatherIfNeeded(
                                        for: planner.location
                                    )
                            }
                        }
                        .navigationTransition(
                            .zoom(
                                sourceID: "LOCATION",
                                in: sheetAnimation
                            )
                        )
                    }
                }

                // Slide to modified events once the UI has settled.
                .onChange(of: sortedOpenPlans.map(\.id)) { _, _ in
                    attemptScrollToEvent(
                        proxy: proxy
                    )
                }
                .onChange(of: pendingScroll) { _, _ in
                    attemptScrollToEvent(
                        proxy: proxy
                    )
                }
            }
            .environmentObject(plannerManager)
            .task {
                modelContext.ensurePlanner(
                    planners: planners,
                    datestamp: datestamp
                )

                modelContext.ensureCalendarSettings(
                    settings: calendarSettingsList
                )

                calendarStore.ensureCalendarEvents(
                    for: datestamp,
                    hiddenCalendarIds: calendarSettings!.hiddenCalendarIds
                )

                // Setup the planner managers.
                calendarEventToggler.calendarSettings = calendarSettings
                plannerManager.setToggleItem(calendarEventToggler.toggleEvent)
                plannerManager.setStatusChecker(
                    calendarEventToggler.isPlannerEventChecked
                )
            }

            // Calendar Data
            .externalData(
                key: calendarStore.refreshKey,
                ready: planner != nil && calendarSettings != nil,
                load: synchronizeCalendarEvents
            )

            // Weather Data
            .externalData(key: weatherStore.refreshKey, ready: planner != nil) {
                Task {
                    await weatherStore.loadWeatherIfNeeded(
                        for: planner?.location
                    )
                }
            }
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topLeftToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Back", systemImage: "chevron.left") {
                closePlanner()
            }
        }
    }

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button(
                    action: {
                        plannerType == .future
                            ? planner?.showCanceled.toggle()
                            : planner?.showCompleted.toggle()
                    },
                    label: {
                        Text(
                            plannerType.getToggleVisibilityLabel(
                                showChecked
                            )
                        )
                        Image(
                            systemName: showChecked
                                ? "eye.slash" : "eye"
                        )
                    }
                )

                Menu {
                    Button(role: .destructive) {
                        isDeleteCheckedConfirmationOpen = true
                    } label: {
                        Text(plannerType.deleteCheckedLabel)
                        Image(systemName: "trash")
                    }
                    .disabled(rawCheckedEvents.isEmpty)

                } label: {
                    Text("Delete options")
                    Image(systemName: "trash")
                }

            } label: {
                Image(systemName: "ellipsis")
            }
            .confirmationDialog(
                plannerType.deleteCheckedConfirmationTitle,
                isPresented: $isDeleteCheckedConfirmationOpen,
                titleVisibility: .visible
            ) {
                Button("Confirm", role: .destructive) {
                    deleteAllCheckedEvents()
                }
            } message: {
                Text(
                    "Calendar events will not be deleted. This action is irreversible."
                )
            }
        }
    }

    @ToolbarContentBuilder
    private func bottomToolbar(_ proxy: ScrollViewProxy) -> some ToolbarContent
    {
        ToolbarItemGroup(placement: .bottomBar) {
            Spacer()

            Button("Add", systemImage: "plus") {
                if let last = sortedOpenPlans.last,
                    last.title.isEmpty
                {
                    return
                }

                DispatchQueue.main.async {
                    withAnimation {
                        proxy.scrollTo("UNCHECKED", anchor: .bottom)
                    }
                }

                createEvent(at: sortedOpenPlans.count)
            }
            .tint(accentColor.swiftUIColor)
        }
    }

    // MARK: - Data Handlers

    private func synchronizeCalendarEvents() {
        calendarPlannerEvents =
            modelContext.synchronize(
                calendarEvents: calendarStore.singleDayEventsByDatestamp[
                    datestamp
                ] ?? [],
                into: planner,
                with: calendarSettings
            ) ?? calendarPlannerEvents
    }

    private func reloadCalendar() {
        calendarStore.refresh(
            hiddenCalendarIds: calendarSettings?
                .hiddenCalendarIds ?? []
        )
    }

    // MARK: - List Actions

    private func createEvent(
        near baseId: PersistentIdentifier?,
        offset: Int = 0
    ) {
        guard
            let baseIndex = sortedOpenPlans.firstIndex(where: {
                $0.id == baseId
            })
        else {
            return
        }

        let finalIndex = baseIndex + offset

        // Don't create the new item if it is next to an empty item.
        let upperEvent = finalIndex > 0 ? sortedOpenPlans[finalIndex - 1] : nil
        let lowerEvent =
            finalIndex < sortedOpenPlans.count
            ? sortedOpenPlans[finalIndex] : nil
        if let upper = upperEvent, upper.title.isEmpty {
            return
        }
        if let lower = lowerEvent, lower.title.isEmpty {
            return
        }

        createEvent(at: finalIndex)
    }

    private func createEvent(at index: Int) {
        guard let planner = planner else { return }
        let sortIndex = generateSortIndex(index: index, items: sortedOpenPlans)
        let newEvent = PlannerEvent(sortIndex: sortIndex, planner: planner)

        modelContext.insert(newEvent)
        try! modelContext.save()
    }

    private func handleMoveUncheckedEvent(from: Int, to: Int) {
        guard from != to else { return }

        // 1: Force-save the event to its new position.
        let movedEvent = sortedOpenPlans[from]
        let eventsWithoutEvent = sortedOpenPlans.filter {
            $0.id != movedEvent.id
        }
        let newSortIndex = generateSortIndex(
            index: to,
            items: eventsWithoutEvent
        )
        movedEvent.sortIndex = newSortIndex

        // Save the calendar event position.
        if movedEvent.calendarEvent != nil && calendarSettings != nil {
            calendarSettings!.sortIndexMap[
                movedEvent.calendarEvent!.calendarItemExternalIdentifier
            ] = movedEvent.sortIndex
        }

        try! modelContext.save()

        // 2: After UI settles, validate correct chronological insertion.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 sec

            let validSortIndex = generateValidPlannerEventSortIndex(
                for: movedEvent,
                in: sortedOpenPlans
            )
            if validSortIndex != newSortIndex {
                movedEvent.sortIndex = validSortIndex

                // Save the calendar event position.
                if movedEvent.calendarEvent != nil
                    && calendarSettings != nil
                {
                    calendarSettings!.sortIndexMap[
                        movedEvent.calendarEvent!.calendarItemExternalIdentifier
                    ] = movedEvent.sortIndex
                }

                try! modelContext.save()
            }
        }
    }

    private func handleEventTitleChange(event: PlannerEvent) {
        // 1. TODO: Handle recurring events here

        // 2. Update the device calendar with the new title.
        guard event.calendarEvent == nil else {
            event.calendarEvent!.title = event.title
            try! calendarStore.ekEventStore.save(
                event.calendarEvent!,
                span: .thisEvent
            )
            return
        }

        guard let datestamp = event.planner?.datestamp else { return }

        // 3. Build the data from the event title.
        guard
            let (timeValue, updatedText) = event.title.separateTimeValue()
        else {
            return
        }

        guard
            let date = timeValue.toDate(
                for: datestamp
            )
        else {
            return
        }

        event.title = updatedText
        event.date = date

        // 4. Validate sort order.
        let newSortIndex = generateValidPlannerEventSortIndex(
            for: event,
            in: sortedOpenPlans
        )

        guard newSortIndex != event.sortIndex else {
            do {
                try modelContext.save()
            } catch {
                assertionFailure(
                    "Failed to save new item after time smart-detect: \(error)"
                )
            }
            return
        }

        event.sortIndex = newSortIndex
        pendingScroll = .planner(id: event.id, sortIndex: newSortIndex)

        do {
            try modelContext.save()
        } catch {
            assertionFailure(
                "Failed to save new item after time smart-detect: \(error)"
            )
        }
    }

    // MARK: - Overflow Actions

    private func deleteAllCheckedEvents() {
        guard let planner else {
            return
        }

        modelContext.deleteCheckedPlans(from: planner)

        reloadCalendar()
    }

    // MARK: - Helpers

    private func attemptScrollToEvent(
        proxy: ScrollViewProxy
    ) {
        guard let pending = pendingScroll, pending.isScrollable else {
            return
        }

        let targetEvent: PlannerEvent? = {
            if let plannerId = pending.plannerId {
                return sortedOpenPlans.first(where: { $0.id == plannerId })
            }

            if let calendarId = pending.calendarId {
                return sortedOpenPlans.first(
                    where: { $0.calendarEvent?.eventIdentifier == calendarId }
                )
            }

            return nil
        }()

        guard
            let event = targetEvent,
            let targetSortIndex = pending.targetSortIndex,
            event.sortIndex == targetSortIndex
        else {
            // List not ready yet. Wait for next change.
            return
        }

        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo("\(event.id)", anchor: .center)
            }
        }

        pendingScroll = nil
    }

}
