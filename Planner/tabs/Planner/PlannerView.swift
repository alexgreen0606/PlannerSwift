//
//  PlannerView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftDate
import SwiftUI

// TODO: when item is unchecked, re-evaluate its chronological ordering

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
    let datestamp: String

    @AppStorage("showChecked") var showChecked: Bool = false

    @Environment(\.modelContext) private var modelContext
    @Query private var uncheckedEvents: [PlannerEvent]
    @Query private var checkedEvents: [PlannerEvent]

    @EnvironmentObject var todaystampManager: TodaystampManager
    @EnvironmentObject var plannerManager: ListManager

    @State private var navigationManager = NavigationManager.shared
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isCalendarPickerPresented = false

    var plannerType: PlannerType {
        datestamp <= todaystampManager.todaystamp ? .pastOrPresent : .future
    }

    // Query events matching the given datestamp.
    init(datestamp: String) {
        self.datestamp = datestamp

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
                endAdornment: timeValue,
                customToggleConfig: plannerType.toggleEventIconConfig,
                checkedHeader: plannerType.checkedHeader,
                checkedFooter: plannerType.getCheckedFooter(for: datestamp),
                onCreateItem: handleCreateEvent,
                onTitleChange: handleEventTitleChange,
                onMoveUncheckedItem: handleMoveUncheckedEvent
            )
            .navigationTitle(navigationManager.selectedPlannerDate.dayName)
            .navigationSubtitle(navigationManager.selectedPlannerDate.longDate)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Calendar", systemImage: "calendar") {
                        isCalendarPickerPresented = true
                    }
                    .tint(Color(uiColor: .label))
                    .popover(isPresented: $isCalendarPickerPresented) {
                        VStack {
                            DatePicker(
                                "Open a planner",
                                selection: $navigationManager
                                    .selectedPlannerDate,
                                displayedComponents: .date
                            )
                            .frame(width: 290, height: 290)
                            .clipped()
                            .padding()
                            .datePickerStyle(.graphical)
                            .presentationCompactAdaptation(.popover)
                            .onChange(of: navigationManager.selectedPlannerDate)
                            { _, newDate in
                                let newStamp = newDate.toFormat("yyyy-MM-dd")
                                var transaction = Transaction(animation: .none)
                                transaction.disablesAnimations = true
                                withTransaction(transaction) {
                                    if newStamp == todaystampManager.todaystamp
                                    {
                                        // Clear the navigation stack when going back to today's planner.
                                        navigationManager.plannerPath =
                                            NavigationPath()
                                    } else {
                                        navigationManager.plannerPath.append(
                                            newStamp
                                        )
                                    }
                                }
                                isCalendarPickerPresented = false
                            }
                        }
                        .presentationCompactAdaptation(.popover)
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

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        if let last = uncheckedEvents.last, last.title.isEmpty {
                            return
                        }

                        // TODO: doesnt work when the list is long and hasn't been scrolled down to yet (not mounted?)
                        slideTo("bottom", at: .top)
                        handleCreateEvent(at: uncheckedEvents.count)
                    }
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

#Preview {
    PlannerView(datestamp: "2025-12-10")
}
