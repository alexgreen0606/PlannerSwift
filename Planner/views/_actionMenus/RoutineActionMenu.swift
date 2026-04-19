//
//  RoutineActionMenu.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftData
import SwiftUI

// Clean

struct RoutineActionMenuView: View {
    let weekday: Weekday
    let sortedRoutineEvents: [RoutineEvent]

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var routineManager: ListManager<RoutineEvent>
    @EnvironmentObject private var calendarStore: CalendarStore

    @State private var showDeleteRoutineConfirmation = false

    private var deleteConfig: ConfirmationConfig {
        deleteRoutineConfig(weekday: weekday, delete: deleteRoutine)
    }

    // MARK: - Body

    var body: some View {
        Menu("Routine Action Menu", systemImage: "ellipsis") {
            selectEventsButton
            deleteRoutineButton
        }

        // MARK: Delete Routine Confirmation
        .withConfirmation(
            deleteConfig,
            isPresented: $showDeleteRoutineConfirmation
        )
    }

    // MARK: - View Builders

    private var selectEventsButton: some View {
        Button {
            routineManager.toggleSelectMode()
        } label: {
            Label(
                "Select Events",
                systemImage: "checkmark.circle"
            )
        }
        .disabled(sortedRoutineEvents.isEmpty)
    }

    private var deleteRoutineButton: some View {
        Button(role: .destructive) {
            showDeleteRoutineConfirmation = true
        } label: {
            Label(
                "Delete Routine",
                systemImage: "trash"
            )
        }
        .disabled(sortedRoutineEvents.isEmpty)
    }

    // MARK: - Functions

    private func deleteRoutine() {
        modelContext.deleteRoutineEvents(
            sortedRoutineEvents,
            from: weekday,
            ekEventStore: calendarStore.ekEventStore
        )
    }

}
