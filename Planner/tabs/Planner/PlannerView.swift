//
//  PlannerView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftDate
import SwiftUI

extension String {
    func toDate() -> Date? {
        // TODO: use SwiftDate
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: self)
    }
}

// TODO: use SwiftDate
extension Date {
    var dayName: String {
        let df = DateFormatter()
        df.dateFormat = "EEEE"  // Ex: Wednesday
        return df.string(from: self)
    }

    var longDate: String {
        let df = DateFormatter()
        df.dateStyle = .long  // Ex: October 24, 2025
        return df.string(from: self)
    }
}

struct PlannerView: View {
    let datestamp: String

    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject var todaystampManager: TodaystampManager

    @Query private var events: [PlannerEvent]
    
    @State var navigationManager = NavigationManager.shared
    @State private var scrollProxy: ScrollViewProxy?
    @State private var showCompleted: Bool = false
    @State private var isCalendarPickerPresented = false

    var isTodayOrEarlier: Bool {
        datestamp <= todaystampManager.todaystamp
    }

    init(datestamp: String) {
        self.datestamp = datestamp

        // Show events matching the given datestamp.
        _events = Query(
            filter: #Predicate<PlannerEvent> {
                $0.datestamp == datestamp && (showCompleted || !$0.isComplete)
            },
            sort: \PlannerEvent.sortIndex
        )
    }

    private func timeValue(_ event: PlannerEvent) -> AnyView {
        guard let isoTimestamp = getPlannerEventTime(event: event) else {
            return AnyView(EmptyView())
        }
        guard let (time, indicator) = isoToTimeValues(iso: isoTimestamp) else {
            return AnyView(EmptyView())
        }

        let isEndEvent =
            event.timeConfig?.calendarConfig?.multiDayConfig?.endEventId
            == String(describing: event.id)
        let isStartEvent =
            event.timeConfig?.calendarConfig?.multiDayConfig?.startEventId
            == String(describing: event.id)
        let detail = isEndEvent ? "END" : isStartEvent ? "START" : nil

        return AnyView(
            TimeValue(
                time: time,
                indicator: indicator,
                detail: detail,
                disabled: false
            ) {
                // TODO: open time modal
            }
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            SortableListView<PlannerEvent>(
                items: events,
                toggleType: isTodayOrEarlier ? .complete : .delete,
                endAdornment: timeValue,
                onCreateItem: createEvent,
                onTitleChange: handleEventTitleChange,
                onMoveItem: handleMoveEvent
            )
            .navigationTitle(navigationManager.selectedPlannerDate.dayName)
            .navigationSubtitle(navigationManager.selectedPlannerDate.longDate)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Calendar", systemImage: "calendar") {
                        isCalendarPickerPresented = true
                    }
                    .popover(isPresented: $isCalendarPickerPresented) {
                        VStack {
                            DatePicker(
                                "Open a planner",
                                selection: $navigationManager
                                    .selectedPlannerDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .presentationCompactAdaptation(.popover)
                            .onChange(of: navigationManager.selectedPlannerDate)
                            { _, newDate in
                                let newStamp = newDate.toFormat("yyyy-MM-dd")
                                var transaction = Transaction(animation: .none)
                                transaction.disablesAnimations = true
                                withTransaction(transaction) {
                                    navigationManager.path.append(newStamp)
                                }
                                isCalendarPickerPresented = false
                            }
                        }
                        .frame(width: 340, height: 320)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("More", systemImage: "ellipsis") {

                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        if let last = events.last, last.title.isEmpty {
                            return
                        }
                        slideToBottom()
                        createEvent(events.count)
                    }
                }
            }
            .onAppear {
                scrollProxy = proxy
            }
        }
    }

    func handleMoveEvent(from: Int, to: Int) {
        guard from != to else { return }

        // 1: Force-save the event to its new position.
        let movedEvent = events[from]
        let eventsWithoutEvent = events.filter { $0.id != movedEvent.id }
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
                events: events
            )
            if validSortIndex != newSortIndex {
                movedEvent.sortIndex = validSortIndex
                try! modelContext.save()
            }
        }
    }

    func handleEventTitleChange(event: PlannerEvent) {
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
            let (timeValue, updatedText) = separateTimeValue24HourFromText(
                event.title
            )
        else {
            return
        }
        guard
            let config = createPlannerEventTimeConfig(
                datestamp: event.datestamp,
                timeValue: timeValue
            )
        else {
            return
        }

        event.title = updatedText
        event.timeConfig = config

        // 4. Validate sort order.
        let newSortIndex = generateValidPlannerEventSortIndex(
            event: event,
            events: events
        )
        if newSortIndex != event.sortIndex {
            event.sortIndex = newSortIndex
            try? modelContext.save()
            snapToId(id: event.id)
        }
    }

    private func createEvent(_ index: Int) {
        let sortIndex = generateSortIndex(index: index, items: events)
        let newEvent = PlannerEvent(datestamp: datestamp, sortIndex: sortIndex)
        modelContext.insert(newEvent)
        try! modelContext.save()
    }

    private func slideToBottom() {
        guard let proxy = scrollProxy
        else { return }
        withAnimation(.linear(duration: 2)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }

    // TODO: test if this is needed due to animation of textfield to its new location
    private func snapToId(id: ObjectIdentifier?) {
        guard let id,
            let proxy = scrollProxy
        else { return }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1
        ) {
            proxy.scrollTo(id, anchor: .bottom)
        }
    }

}

#Preview {
    PlannerView(datestamp: "2025-12-10")
}
