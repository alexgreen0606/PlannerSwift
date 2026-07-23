//
//  SelectedRoutineEventActions.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftData
import SwiftUI

struct SelectedRoutineEventActionsView: View {
    @Binding var showTransferSheet: Bool
    let routine: Routine
    let weekday: Weekday
    let namespace: Namespace.ID
    let settings: Settings

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var routineEngine:
        ListEngine<RoutineEventContext>
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService

    @State private var showDeleteConfirmation = false

    private var deleteConfirmation: ConfirmationConfig {
        bulkRemoveRoutineEventFromWeekdayConfig(
            routineEventContexts: routineEngine.selectedItems,
            weekday: weekday,
            remove: deleteSelectedEventsFromWeekday,
            delete: deleteSelectedEventsEverywhere
        )
    }

    // MARK: - Body

    var body: some View {
        HStack {
            DeleteSelectedButtonView<RoutineEventContext>(
                confirmationConfig: deleteConfirmation
            )

            Spacer()

            TransferSelectedButtonView<RoutineEventContext>(
                showTransferSheet: $showTransferSheet,
                systemImage: "plus.square.on.square",
                namespace: namespace
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Functions

    private func deleteSelectedEventsFromWeekday() {
        let selections = routineEngine.selectedItems

        routineEngine.clearSelections()

        DispatchQueue.main.async {
            modelContext.removeRoutineEventContextsFromRoutine(
                routineEventContexts: selections,
                routine: routine,
                todayStartOfDay: todayService.todayPlanner.startOfDay(
                    settings: settings
                ),
                ekEventStore: calendarService.ekEventStore
            )

            DispatchQueue.main.async(execute: routineEngine.toggleSelectMode)
        }
    }

    private func deleteSelectedEventsEverywhere() {
        let selections = routineEngine.selectedItems

        routineEngine.clearSelections()

        DispatchQueue.main.async {
            modelContext.deleteRoutineEventContexts(
                selections,
                todayStartOfDay: todayService.todayPlanner.startOfDay(
                    settings: settings
                ),
                ekEventStore: calendarService.ekEventStore
            )

            DispatchQueue.main.async(execute: routineEngine.toggleSelectMode)
        }
    }
}
