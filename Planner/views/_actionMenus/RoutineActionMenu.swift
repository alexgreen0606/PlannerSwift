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
    @EnvironmentObject private var calendarStore: CalendarStore

    @State private var showDeleteWeekdayEventsConfirmation = false
    @State private var showDeleteAllRoutinesConfirmation = false

    private var isToday: Bool {
        todaystampWatcher.todaystamp.weekday == weekday.label
    }

    var body: some View {
        Menu("Routine Action Menu", systemImage: "ellipsis") {
            selectEventsButton
            deleteActionsMenu
        }

        // MARK: Delete Weekday Events Confirmation
        .confirmationDialog(
            "Delete \(weekday.label) routine?",
            isPresented: $showDeleteWeekdayEventsConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Confirm",
                role: .destructive,
                action: deleteWeekdayEvents
            )
        } message: {
            Text(
                "Future occurrences will be deleted from your planner on \(weekday.label)s. Other days will not be affected. This action cannot be undone."
            )
        }

        // MARK: Delete All Routines Confirmation
        .confirmationDialog(
            "Delete all routines?",
            isPresented: $showDeleteAllRoutinesConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Confirm",
                role: .destructive,
                action: deleteRotuines
            )
        } message: {
            Text(
                "Future occurrences will be deleted from your planner. All days will be affected. This action cannot be undone."
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
            deleteWeekdayEventsButton
            deleteAllRoutinesButton
        } label: {
            Label(
                "Delete options",
                systemImage: "trash"
            )
        }
    }

    private var deleteWeekdayEventsButton: some View {
        Button("Delete \(weekday.label) routine", role: .destructive) {
            showDeleteWeekdayEventsConfirmation = true
        }
        .disabled(sortedRoutineEvents.isEmpty)
    }

    private var deleteAllRoutinesButton: some View {
        Button("Delete all routines", role: .destructive) {
            showDeleteAllRoutinesConfirmation = true
        }
        .disabled(sortedRoutineEvents.isEmpty)
    }

    // MARK: - Functions

    private func deleteWeekdayEvents() {
        modelContext.deleteRoutineEvents(
            sortedRoutineEvents,
            from: weekday,
            ekEventStore: calendarStore.ekEventStore
        )
    }

    private func deleteRotuines() {
        modelContext.deleteAllRoutines(
            ekEventStore: calendarStore.ekEventStore
        )
    }

}
