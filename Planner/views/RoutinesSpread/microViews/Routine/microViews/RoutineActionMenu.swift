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
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher

    @State private var showDeleteConfirmation = false

    private var isToday: Bool {
        todaystampWatcher.todaystamp.weekday == weekday.label
    }

    var body: some View {
        Menu("Routine Action Menu", systemImage: "ellipsis") {
            selectEventsButton
            deleteActionsMenu
        }

        // MARK: Delete Events Confirmation
        .confirmationDialog(
            "Delete every recurring event?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Confirm",
                role: .destructive,
                action: deleteAllEvents
            )
        } message: {
            Text(
                "This will delete all occurrences of the events from your planner. Other routine days will not be affected. This action cannot be undone."
            )
        }
    }

    // MARK: - View Builders

    // MARK: Select Events Button

    private var selectEventsButton: some View {
        Button {
            routineManager.toggleSelectMode()
        } label: {
            Label(
                "Select events",
                systemImage: "checkmark.circle"
            )
        }
        .disabled(sortedRoutineEvents.isEmpty)
    }

    // MARK: Delete Menu

    private var deleteActionsMenu: some View {
        Menu {
            deleteAllEventsButton
        } label: {
            Label(
                "Delete options",
                systemImage: "trash"
            )
        }
    }

    private var deleteAllEventsButton: some View {
        Button("Delete all events", role: .destructive) {
            showDeleteConfirmation = true
        }
        .disabled(sortedRoutineEvents.isEmpty)
    }

    // MARK: - Functions

    private func deleteAllEvents() {
        modelContext.deleteRoutineEvents(
            from: sortedRoutineEvents,
            for: weekday
        )
    }

}
