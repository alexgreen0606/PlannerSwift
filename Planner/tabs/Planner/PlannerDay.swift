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

    var checkedHeader: String {
        switch self {
        case .pastOrPresent: "Completed plans"
        case .future: "Canceled plans"
        }
    }

    func getCheckedFooter(for datestamp: String) -> String? {
        switch self {
        case .pastOrPresent:
            return nil

        case .future:
            guard
                let date = datestamp.toDate("yyyy-MM-dd", region: .current)?
                    .date
            else {
                return nil
            }

            let formatted = date.subHeader
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

struct PlannerView: View {
    let datestamp: String
    let closePlanner: () -> Void

    @AppStorage("showCompletedPlans") var showCompletedPlans: Bool = false
    @AppStorage("showDeletedPlans") var showDeletedPlans: Bool = false
    @AppStorage("themeColor") var themeColor: ThemeColorOption =
        ThemeColorOption.blue

    @Environment(\.modelContext) private var modelContext
    @Query private var planners: [Planner]
    @State private var planner: Planner?

    @EnvironmentObject var todaystampManager: TodaystampManager
    @EnvironmentObject var plannerManager: ListManager
    @State var calendarEventStore = CalendarEventStore.shared
    @State private var navigationManager = NavigationManager.shared

    @Namespace private var calendarEventSheetNamespace
    @State private var calendarEventEditConfig: CalendarEventEditConfig?

    @State private var scrollProxy: ScrollViewProxy?
    @State private var isCalendarPickerPresented = false

    var plannerType: PlannerType {
        datestamp <= todaystampManager.todaystamp ? .pastOrPresent : .future
    }

    var date: Date {
        datestamp.date ?? Date()
    }

    var showChecked: Bool {
        plannerType == .future ? showDeletedPlans : showCompletedPlans
    }

    var uncheckedEvents: [PlannerEvent] {
        planner != nil
            ? planner!.events.filter {
                !$0.isChecked
            }.sorted { $0.sortIndex < $1.sortIndex }
            : []
    }

    var checkedEvents: [PlannerEvent] {
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
                    chipAnimation: calendarEventSheetNamespace,
                    openCalendarEvent: openCalendarEventModal
                ),
                endAdornment: timeValue,
                customToggleConfig: plannerType.toggleEventIconConfig,
                checkedHeader: plannerType.checkedHeader,
                checkedFooter: plannerType.getCheckedFooter(for: datestamp),
                emptyUncheckedLabel: "No plans",
                emptyCheckedLabel: "No completed plans",
                onCreateItem: handleCreateEvent,
                onTitleChange: handleEventTitleChange,
                onMoveUncheckedItem: handleMoveUncheckedEvent
            )
            .navigationTitle(date.header)
            .navigationSubtitle(date.subHeader)
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
                                    ? showDeletedPlans.toggle()
                                    : showCompletedPlans.toggle()
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

                        // TODO: doesnt work when the list is long and hasn't been scrolled down to yet (not mounted?)
                        slideTo("UNCHECKED", at: .bottom)
                        handleCreateEvent(at: uncheckedEvents.count)
                    }
                    .buttonStyle(.glassProminent)
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
                slideTo("CHECKED", at: .top)
            }
        }
        .task {
            ensurePlanner()
        }
        .sheet(item: $calendarEventEditConfig) { destination in
            switch destination {
            case .edit(let event):
                EditCalendarEventView(
                    event: event,
                    eventStore: calendarEventStore.ekEventStore
                ) { action, updatedEvent in
                    calendarEventStore.refresh()
                    calendarEventEditConfig = nil
                }
                .tint(themeColor.swiftUIColor)
                .ignoresSafeArea()
                .navigationTransition(
                    .zoom(
                        sourceID: String(describing: event.eventIdentifier),
                        in: calendarEventSheetNamespace
                    )
                )

            case .view(let event):
                ViewCalendarEventView(event: event)
                    .tint(themeColor.swiftUIColor)
                    .presentationDetents([.height(340)])
                    .ignoresSafeArea()
                    .navigationTransition(
                        .zoom(
                            sourceID: String(describing: event.eventIdentifier),
                            in: calendarEventSheetNamespace
                        )
                    )
            }
        }
    }

    @ViewBuilder
    private func timeValue(_ event: PlannerEvent) -> some View {
        if let iso = getPlannerEventTime(event: event),
            let (time, indicator) = iso.toTimeValues()
        {
            let isEnd =
                event.timeConfig?.calendarConfig?.multiDayConfig?.endEventId
                == String(describing: event.id)

            let isStart =
                event.timeConfig?.calendarConfig?.multiDayConfig?.startEventId
                == String(describing: event.id)

            let detail = isEnd ? "END" : isStart ? "START" : nil

            TimeValue(
                time: time,
                indicator: indicator,
                detail: detail,
                disabled: false,
                color: Color.blue
            ) {
                // TODO: open time modal
            }
        } else {
            EmptyView()
        }
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
                try! modelContext.save()
            }
        }
    }

    private func handleEventTitleChange(event: PlannerEvent) {
        guard let datestamp = event.planner?.datestamp else { return }

        // 1. Recurring event: delete and clone event.
        if event.recurringId != nil {
            // TODO: Handle recurring events in future
        }

        // 2. Only analyze text if event has no associated time config.
        guard event.timeConfig == nil else {
            // TODO: save to calendar here
            return
        }

        // 3. Build the data from the event title.
        guard
            let (timeValue, updatedText) = event.title.separateTimeValue()
        else {
            return
        }
        guard
            let config = timeValue.toPlannerEventTimeConfig(
                usingDate: datestamp
            )
        else {
            return
        }

        event.title = updatedText
        event.timeConfig = config

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
        slideTo(event.id, at: .bottom, withDelay: .seconds(3))

        try? modelContext.save()
    }

    private func slideTo(
        _ id: any Hashable,
        at anchor: UnitPoint,
        withDelay delay: DispatchTimeInterval = .seconds(0)
    ) {
        guard let proxy = scrollProxy
        else { return }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay
        ) {
            withAnimation(.linear(duration: 2)) {
                proxy.scrollTo(id, anchor: anchor)
            }
        }
    }

    private func openCalendarEventModal(for event: EKEvent) {
        if event.calendar.allowsContentModifications {
            calendarEventEditConfig = .edit(event)
        } else {
            calendarEventEditConfig = .view(event)
        }
    }

    @MainActor
    private func ensurePlanner() {
        if let storagePlanner = planners.first {
            planner = storagePlanner
        } else if planner == nil {
            // Only create if planner doesn't exist yet.
            let newPlanner = Planner(
                datestamp: datestamp
            )
            modelContext.insert(newPlanner)
            try! modelContext.save()

            planner = newPlanner
        }
    }
}
