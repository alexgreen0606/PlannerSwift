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

enum PlannerType: String {
    case pastOrPresent
    case future

    var toggleEventIconConfig: CustomIconConfig? {
        switch self {
        case .pastOrPresent: nil
        case .future:
            CustomIconConfig(
                name: "circle.slash",
                primaryColor: .red,
                secondaryColor: Color(uiColor: .secondaryLabel)
            )
        }
    }

    var emptyCheckedLabel: String {
        switch self {
        case .pastOrPresent: "No completed plans"
        case .future: "No canceled plans"
        }
    }

    var checkedHeader: String {
        switch self {
        case .pastOrPresent: "Completed plans"
        case .future: "Cancelled plans"
        }
    }

    var deleteCheckedLabel: String {
        switch self {
        case .pastOrPresent: "Delete completed plans"
        case .future: "Delete canceled plans"
        }
    }

    var deleteCheckedConfirmationTitle: String {
        switch self {
        case .pastOrPresent: "Delete completed plans from this planner?"
        case .future: "Delete canceled plans from this planner?"
        }
    }

    func getCheckedFooter(for datestamp: String) -> String? {
        switch self {
        case .pastOrPresent:
            return nil

        case .future:
            guard
                let date = datestamp.toDate("yyyy-MM-dd", region: .local)?
                    .date
            else {
                return nil
            }

            let formatted = date.dynamicSubheader
            return
                "These canceled plans will be deleted the morning of \(formatted)."
        }
    }

    func getToggleVisibilityLabel(_ showHidden: Bool) -> String {
        switch self {
        case .pastOrPresent: showHidden ? "Hide completed" : "Show completed"
        case .future: showHidden ? "Hide canceled" : "Show canceled"
        }
    }
}

struct CalendarEventSheetContext: Identifiable {
    var event: EKEvent
    var namespace: Namespace.ID

    var id: String {
        "\(String(describing: event.eventIdentifier))-\(namespace)"
    }
}

struct PlannerView: View {
    private let datestamp: String
    private let closePlanner: () -> Void

    @AppStorage("themeColor") var themeColor: ThemeColorOption =
        ThemeColorOption.blue

    @Environment(\.modelContext) private var modelContext
    @Query private var planners: [Planner]
    @Query private var calendarSettingsList: [CalendarSettings]

    @EnvironmentObject var calendarStore: CalendarStore
    @EnvironmentObject var todaystampManager: TodaystampWatcher

    @StateObject private var plannerManager = ListManager<PlannerEvent>()

    @State private var calendarPlannerEvents: [PlannerEvent] = []
    @State private var calendarEventSheetContext: CalendarEventSheetContext?
    @Namespace private var sheetAnimation

    @State private var calendarEventToggler: CalendarEventToggler?
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isCalendarPickerPresented = false
    @State private var isDeleteCheckedConfirmationOpen = false
    
    private var calendarSettings: CalendarSettings? {
        calendarSettingsList.first
    }

    private var planner: Planner? {
        planners.first
    }

    private var plannerType: PlannerType {
        datestamp <= todaystampManager.todaystamp ? .pastOrPresent : .future
    }

    private var date: Date {
        datestamp.date ?? Date()
    }

    private var showChecked: Bool {
        plannerType == .future
            ? planner?.showCanceled == true : planner?.showCompleted == true
    }

    private var hasCheckedEvents: Bool {
        planner?.events.contains(where: \.isChecked) ?? false
    }

    private var uncheckedEvents: [PlannerEvent] {
        guard let planner, let calendarEventToggler else {
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

    private var checkedEvents: [PlannerEvent] {
        guard let planner, let calendarEventToggler else {
            return []
        }

        let combinedEvents = planner.events + calendarPlannerEvents

        return combinedEvents
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
        ScrollViewReader { proxy in
            SortableListView<
                PlannerEvent, AnyView, PlannerChipSpreadView
            >(
                uncheckedItems: uncheckedEvents,
                checkedItems: checkedEvents,
                showChecked: showChecked,
                floatingInfo: PlannerChipSpreadView(
                    datestamp: datestamp,
                    events: calendarStore.allDayEventsByDatestamp[
                        datestamp
                    ] ?? [],
                    showCountdown: true,
                    showWeather: true,
                    iconMap: calendarSettings?.iconMap ?? [:],
                    animation: sheetAnimation,
                    openCalendarEventSheet: { event in
                        calendarEventSheetContext = CalendarEventSheetContext(
                            event: event,
                            namespace: sheetAnimation
                        )
                    }
                ),
                customToggleConfig: plannerType.toggleEventIconConfig,
                checkedHeader: plannerType.checkedHeader,
                checkedFooter: plannerType.getCheckedFooter(for: datestamp),
                emptyUncheckedLabel: "No plans",
                emptyCheckedLabel: plannerType.emptyCheckedLabel,
                tint: themeColor.swiftUIColor,
                getEndAdornment: { event in
                    AnyView(
                        event.timeValueView(
                            for: datestamp,
                            openPlannerEventSheet: openPlannerEventSheet,
                            openCalendarEventSheet: openCalendarEventSheet,
                            animation: sheetAnimation
                        )
                    )
                },
                createItem: createEvent,
                handleTitleChange: handleEventTitleChange,
                moveItem: handleMoveUncheckedEvent,
                isItemChecked: calendarEventToggler?.isPlannerEventChecked
            )
            .environmentObject(plannerManager)
            .navigationTitle(date.dynamicHeader)
            .navigationSubtitle(date.dynamicSubheader)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back", systemImage: "chevron.down") {
                        closePlanner()
                    }
                }

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
                            .disabled(!hasCheckedEvents)

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
                            "This action is irreversible."
                        )
                    }
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()

                    Button("Add", systemImage: "plus") {
                        if let last = uncheckedEvents.last, last.title.isEmpty {
                            return
                        }

                        scrollProxy?.slideTo("UNCHECKED", at: .bottom)
                        handleCreateEvent(at: uncheckedEvents.count)
                    }
                    .tint(themeColor.swiftUIColor)
                }
            }

            .onAppear {
                scrollProxy = proxy
            }
        }
        // Slide to the checked items when the user marks them visible.
        .onChange(of: showChecked) { _, newShowChecked in
            if newShowChecked {
                scrollProxy?.slideTo("CHECKED", at: .top)
            }
        }
        .task {
            modelContext.ensurePlanner(
                planners: planners,
                datestamp: datestamp
            )

            modelContext.ensureCalendarSettings(
                settings: calendarSettingsList
            )

            synchronizeCalendarEvents()

            // Setup the calendar event handler.
            calendarEventToggler = CalendarEventToggler(
                calendarSettings: calendarSettings
            )

            plannerManager.setToggleItem(calendarEventToggler!.toggleEvent)
            plannerManager.setStatusChecker(calendarEventToggler!.isPlannerEventChecked)
        }
        // Rebuild the planner when the calendar events change.
        .onChange(of: calendarStore.refreshKey) { _, newKey in
            synchronizeCalendarEvents()
        }
        .sheet(item: $calendarEventSheetContext) { context in
            switch context.event.calendar.allowsContentModifications {
            case true:
                EditCalendarEventView(
                    event: context.event,
                    eventStore: calendarStore.ekEventStore
                ) { action, updatedEvent in
                    calendarStore.refresh(
                        hiddenCalendarIds: calendarSettings?.hiddenCalendarIds
                            ?? []
                    )
                    calendarEventSheetContext = nil
                }
                .tint(themeColor.swiftUIColor)
                .ignoresSafeArea()
                .navigationTransition(
                    .zoom(
                        sourceID: String(
                            describing: context.event.eventIdentifier
                        ),
                        in: context.namespace
                    )
                )

            case false:
                ViewCalendarEventView(event: context.event)
                    .tint(themeColor.swiftUIColor)
                    .presentationDetents([.height(340)])
                    .ignoresSafeArea()
                    .navigationTransition(
                        .zoom(
                            sourceID: String(
                                describing: context.event.eventIdentifier
                            ),
                            in: context.namespace
                        )
                    )
            }
        }
    }

    private func createEvent(
        near baseId: PersistentIdentifier?,
        offset: Int = 0
    ) {
        guard
            let baseIndex = uncheckedEvents.firstIndex(where: {
                $0.id == baseId
            })
        else {
            return
        }

        let finalIndex = baseIndex + offset

        // Don't create the new item if it is next to an empty item.
        let upperEvent = finalIndex > 0 ? uncheckedEvents[finalIndex - 1] : nil
        let lowerEvent =
            finalIndex < uncheckedEvents.count
            ? uncheckedEvents[finalIndex] : nil
        if let upper = upperEvent, upper.title.isEmpty {
            return
        }
        if let lower = lowerEvent, lower.title.isEmpty {
            return
        }

        handleCreateEvent(at: finalIndex)
    }

    private func openPlannerEventSheet(
        for event: PlannerEvent
    ) {
        // TODO: open custom sheet
    }

    private func openCalendarEventSheet(
        for event: EKEvent
    ) {
        calendarEventSheetContext = CalendarEventSheetContext(
            event: event,
            namespace: sheetAnimation
        )
    }

    private func handleCreateEvent(at index: Int) {
        guard let planner = planner else { return }
        let sortIndex = generateSortIndex(index: index, items: uncheckedEvents)
        let newEvent = PlannerEvent(sortIndex: sortIndex, planner: planner)

        modelContext.insert(newEvent)
        try! modelContext.save()
    }

    private func handleMoveUncheckedEvent(from: Int, to: Int) {
        guard from != to else { return }

        // 1: Force-save the event to its new position.
        let movedEvent = uncheckedEvents[from]
        let eventsWithoutEvent = uncheckedEvents.filter {
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
                movedEvent.calendarEvent!.eventIdentifier
            ] = movedEvent.sortIndex
        }

        try! modelContext.save()

        // 2: After UI settles, validate correct chronological insertion.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 sec

            let validSortIndex = generateValidPlannerEventSortIndex(
                for: movedEvent,
                in: uncheckedEvents
            )
            if validSortIndex != newSortIndex {
                movedEvent.sortIndex = validSortIndex

                // Save the calendar event position.
                if movedEvent.calendarEvent != nil
                    && calendarSettings != nil
                {
                    calendarSettings!.sortIndexMap[
                        movedEvent.calendarEvent!.eventIdentifier
                    ] = movedEvent.sortIndex
                }

                try! modelContext.save()
            }
        }
    }

    private func handleEventTitleChange(event: PlannerEvent) {
        // 1. TODO: Recurring event: delete and clone event.

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
            in: uncheckedEvents
        )

        guard newSortIndex != event.sortIndex else {
            try? modelContext.save()
            return
        }

        event.sortIndex = newSortIndex
        scrollProxy?.slideTo(event.id, at: .bottom, withDelay: .seconds(1))

        try? modelContext.save()
    }

    private func deleteAllCheckedEvents() {

        checkedEvents
            .forEach { modelContext.delete($0) }

        do {
            try modelContext.save()
        } catch {
            print("Failed to delete checked events:", error)
        }
    }

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
}
