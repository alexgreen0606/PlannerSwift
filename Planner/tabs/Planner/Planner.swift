//
//  PlannerView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

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

            let formatted = date.longDate
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
    @Binding var isPlannerOpen: Bool
    let datestamp: String

    @AppStorage("showChecked") var showChecked: Bool = false
    @AppStorage("themeColor") var themeColor: ThemeColorOption =
        ThemeColorOption.blue

    @Environment(\.modelContext) private var modelContext
    @Query private var uncheckedEvents: [PlannerEvent]
    @Query private var checkedEvents: [PlannerEvent]

    @EnvironmentObject var todaystampManager: TodaystampManager
    @EnvironmentObject var plannerManager: ListManager
    
    @State var calendarEventStore = CalendarEventStore.shared
    @State private var navigationManager = NavigationManager.shared
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isCalendarPickerPresented = false

    var plannerType: PlannerType {
        datestamp <= todaystampManager.todaystamp ? .pastOrPresent : .future
    }
    
    var date: Date {
        datestamp.date ?? Date()
    }

    // Query events matching the given datestamp.
    init(datestamp: String, isPlannerOpen: Binding<Bool>) {
        self.datestamp = datestamp
        self._isPlannerOpen = isPlannerOpen

        _uncheckedEvents = Query(
            filter: #Predicate<PlannerEvent> {
                $0.datestamp == datestamp && !$0.isChecked
            },
            sort: \.sortIndex
        )
        _checkedEvents = Query(
            filter: #Predicate<PlannerEvent> {
                $0.datestamp == datestamp && $0.isChecked
            },
            sort: \.sortIndex
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            SortableListView(
                uncheckedItems: uncheckedEvents,
                checkedItems: checkedEvents,
                floatingInfo: PlannerChipSpreadView(
                    datestamp: datestamp,
                    events: calendarEventStore.allDayEventsByDatestamp[datestamp] ?? [],
                    showCountdown: true
                ),
                endAdornment: timeValue,
                customToggleConfig: plannerType.toggleEventIconConfig,
                checkedHeader: plannerType.checkedHeader,
                checkedFooter: plannerType.getCheckedFooter(for: datestamp),
                onCreateItem: handleCreateEvent,
                onTitleChange: handleEventTitleChange,
                onMoveUncheckedItem: handleMoveUncheckedEvent
            )
            .navigationTitle(date.dayName)
            .navigationSubtitle(date.longDate)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back", systemImage: "chevron.left") {
                        isPlannerOpen.toggle()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(
                            action: {
                                showChecked.toggle()
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
                        slideTo("bottom", at: .top)
                        handleCreateEvent(at: uncheckedEvents.count)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(themeColor.swiftUIColor)
                }
            }
            .onAppear {
                scrollProxy = proxy
            }
            // Slide to the checked items when the user marks them visible.
            .onChange(of: showChecked) { _, newShowChecked in
                if newShowChecked {
                    slideTo("checked", at: .top)
                }
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
                disabled: false
            ) {
                // TODO: open time modal
            }
        } else {
            EmptyView()
        }
    }

    private func handleCreateEvent(at index: Int) {
        let sortIndex = generateSortIndex(index: index, items: uncheckedEvents)
        let newEvent = PlannerEvent(datestamp: datestamp, sortIndex: sortIndex)
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
                usingDate: event.datestamp
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
}
