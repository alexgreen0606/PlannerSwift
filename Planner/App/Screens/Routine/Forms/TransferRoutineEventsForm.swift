//
//  TransferRoutineEventsForm.swift
//  Planner
//
//  Created by Alex Green on 4/8/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

struct TransferRoutineEventsFormView: View {
    private let sourceDayOfWeek: Weekday
    private let sortedSourceRoutineEvents: [RoutineEventContext]
    private let settings: Settings
    private let openRoutine: (Weekday) -> Void

    init(
        sourceDayOfWeek: Weekday,
        sortedSourceRoutineEvents: [RoutineEventContext],
        settings: Settings,
        openRoutine: @escaping (Weekday) -> Void
    ) {
        self.sourceDayOfWeek = sourceDayOfWeek
        self.sortedSourceRoutineEvents = sortedSourceRoutineEvents
        self.settings = settings
        self.openRoutine = openRoutine

        _destinationWeekdays = State(initialValue: [sourceDayOfWeek])
    }

    @Environment(\.showToast) private var showToast
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var routineEngine:
        ListEngine<RoutineEventContext>

    @State private var destinationWeekdays: Set<Weekday> = []

    private var canSave: Bool {
        !destinationWeekdays.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    WeekdayPickerView(selectedWeekdays: $destinationWeekdays)
                        .listRowInsets(.top, 0)
                }
                .listSectionMargins(.top, 0)
                .discreetListItem()
            }
            .scrollDisabled(true)
            .toolbar {
                FormSaveButtonView(canSave: canSave, save: handleTransfer)
            }
            .navigationTitle("Duplicate Recurring Events")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(110)])
    }

    // MARK: - Functions

    private func handleTransfer() {
        plannerService.invalidateRoutines()

        modelContext.bulkUpdateRoutineEventWeekdays(
            routineEngine.selectedItems,
            to: destinationWeekdays,
            sourceSortedRoutineEventContexts: sortedSourceRoutineEvents,
            todayStartOfDay: todayService.todayPlanner.startOfDay(
                settings: settings
            ),
            ekEventStore: calendarService.ekEventStore
        )

        dismiss()

        DispatchQueue.main.async {
            let eventCount = routineEngine.selectedItems.count

            routineEngine.toggleSelectMode()

            DispatchQueue.main.async {
                showNotification(eventCount: eventCount)
            }
        }
    }

    private func showNotification(eventCount: Int) {
        guard !destinationWeekdays.contains(sourceDayOfWeek) else {
            return
        }

        let title: LocalizedStringKey =
            "Successfully \(destinationWeekdays.count > 1 ? "duplicated" : "moved") ^[\(eventCount) recurring event](inflect: true)!"

        var subtitle: LocalizedStringKey?
        var customSubtitle: AnyView?
        var action: (() -> Void)?

        if destinationWeekdays.count == 1 {
            if let destinationDay = destinationWeekdays.first?.rawValue
                .capitalized
            {
                subtitle = "\(destinationDay)s"

                action = {
                    openRoutine(destinationWeekdays.first!)
                }
            }
        } else {
            customSubtitle = AnyView(
                WeekdaySpreadView(
                    selected: destinationWeekdays,
                    accentColor: Color.label
                )
            )
        }

        showToast(
            Toast(
                title: title,
                subtitle: subtitle,
                customSubtitle: customSubtitle,
                iconConfig: IconConfig(
                    name: "arrow.left.arrow.right",
                    primaryColor: Color.label,
                    secondaryColor: Color.label
                ),
                action: action
            )
        )
    }
}
