//
//  RoutineActionMenu.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftData
import SwiftUI

struct RoutineActionMenuView: View {
    let weekday: Weekday
    let routineEvents: [RoutineEvent]

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerSyncService: PlannerSyncService

    @State private var showDeleteRoutineConfirmation = false

    private var deleteConfig: ConfirmationConfig {
        deleteRoutineConfig(weekday: weekday, delete: deleteRoutine)
    }

    // MARK: - Body

    var body: some View {
        Menu("Routine Action Menu", systemImage: "ellipsis") {
            SelectItemsButtonView<RoutineEvent>(
                itemsLabel: "Events",
                hasVisibleItem: !routineEvents.isEmpty
            )

            deleteRoutineButton
        }

        // MARK: Delete Routine Confirmation

        .withConfirmation(
            deleteConfig,
            isPresented: $showDeleteRoutineConfirmation
        )
    }

    // MARK: - View Builders

    private var deleteRoutineButton: some View {
        Button(role: .destructive) {
            showDeleteRoutineConfirmation = true
        } label: {
            Label(
                "Delete Routine",
                systemImage: "trash"
            )
        }
        .disabled(routineEvents.isEmpty)
    }

    // MARK: - Functions

    private func deleteRoutine() {
        modelContext.deleteRoutineEvents(
            routineEvents,
            from: weekday,
            ekEventStore: calendarStore.ekEventStore,
            PlannerSyncStore: plannerSyncService
        )
    }
}
