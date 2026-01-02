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
    @State private var planner: Planner?
    @Query private var calendarEventPositionsList: [CalendarEventPositions]
    @State private var calendarEventPositions: CalendarEventPositions?

    @EnvironmentObject var calendarEventStore: CalendarEventStore
    @EnvironmentObject var todaystampManager: TodaystampWatcher

    @State private var calendarPlannerEvents: [PlannerEvent] = []

    @State private var calendarEventSheetContext: CalendarEventSheetContext?
    @Namespace private var sheetAnimation

    @State private var scrollProxy: ScrollViewProxy?
    @State private var isCalendarPickerPresented = false

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

    private var uncheckedEvents: [PlannerEvent] {
        let storageEvents =
            planner != nil
            ? planner!.events.filter {
                !$0.isChecked
            }
            : []

        return (storageEvents + calendarPlannerEvents).sorted {
            $0.sortIndex < $1.sortIndex
        }
    }

    private var checkedEvents: [PlannerEvent] {
        planner != nil
            ? planner!.events.filter {
                $0.isChecked
            }.sorted { $0.sortIndex < $1.sortIndex }
            : []
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
            SortableListView(
                uncheckedItems: uncheckedEvents,
                checkedItems: checkedEvents,
                showChecked: showChecked,
                floatingInfo: PlannerChipSpreadView(
                    datestamp: datestamp,
                    events: calendarEventStore.allDayEventsByDatestamp[
                        datestamp
                    ] ?? [],
                    showCountdown: true,
                    showWeather: true,
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
                    event.timeValueView(
                        for: datestamp,
                        openPlannerEventSheet: openPlannerEventSheet,
                        openCalendarEventSheet: openCalendarEventSheet,
                        animation: sheetAnimation
                    )
                },
                createItem: handleCreateEvent,
                handleTitleChange: handleEventTitleChange,
                moveItem: handleMoveUncheckedEvent
            )
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
                                        ? "eye.slash.fill" : "eye.fill"
                                )
                            }
                        )
                    } label: {
                        Image(systemName: "ellipsis")
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
            planner = modelContext.ensurePlanner(
                planners: planners,
                datestamp: datestamp
            )

            calendarEventPositions = modelContext.ensureCalendarEventPositions(
                positions: calendarEventPositionsList
            )

            synchronizeCalendarEvents()
        }
        .sheet(item: $calendarEventSheetContext) { context in
            switch context.event.calendar.allowsContentModifications {
            case true:
                EditCalendarEventView(
                    event: context.event,
                    eventStore: calendarEventStore.ekEventStore
                ) { action, updatedEvent in
                    calendarEventStore.refresh()
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

    // TODO: run this whenever the calendar events change
    private func synchronizeCalendarEvents() {
        guard let planner = planner, let positions = calendarEventPositions
        else { return }
        let calendarStoreEvents =
            calendarEventStore.singleDayEventsByDatestamp[datestamp] ?? []
        guard !calendarStoreEvents.isEmpty else { return }

        calendarPlannerEvents =
            planner.synchronizeCalendarEventPositions(
                for: calendarStoreEvents,
                from: positions
            )
    }

    private func openPlannerEventSheet(
        for event: PlannerEvent
    ) {
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
        if movedEvent.calendarEvent != nil && calendarEventPositions != nil {
            calendarEventPositions!.values[
                movedEvent.calendarEvent!.eventIdentifier
            ] = movedEvent.sortIndex
        }

        try! modelContext.save()

        // 2: After UI settles, validate correct chronological insertion.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 sec

            let validSortIndex = generateValidPlannerEventSortIndex(
                event: movedEvent,
                events: uncheckedEvents
            )
            if validSortIndex != newSortIndex {
                movedEvent.sortIndex = validSortIndex

                // Save the calendar event position.
                if movedEvent.calendarEvent != nil
                    && calendarEventPositions != nil
                {
                    calendarEventPositions!.values[
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
            try! calendarEventStore.ekEventStore.save(
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
            event: event,
            events: uncheckedEvents
        )

        guard newSortIndex != event.sortIndex else {
            try? modelContext.save()
            return
        }

        event.sortIndex = newSortIndex
        scrollProxy?.slideTo(event.id, at: .bottom, withDelay: .seconds(3))

        try? modelContext.save()
    }
}
