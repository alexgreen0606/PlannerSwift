//
//  RoutineActionMenu.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftData
import SwiftUI

struct RoutineActionMenuView: View {
    let routine: Routine
    let routineEvents: [RoutineEventContext]
    let weekday: Weekday
    let settings: Settings

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarService
    @EnvironmentObject private var todayService: TodayService

    @State private var showDeleteRoutineConfirmation = false

    private var deleteConfig: ConfirmationConfig {
        deleteRoutineConfig(weekday: weekday, delete: deleteRoutine)
    }

    // MARK: - Body

    var body: some View {
        Menu("", systemImage: "ellipsis") {
            SelectItemsButtonView<RoutineEventContext>(
                itemsLabel: "Events",
                hasVisibleItem: !routineEvents.isEmpty
            )

            deleteActionMenu
        }

        // MARK: Delete Routine Confirmation

        .withConfirmation(
            deleteConfig,
            isPresented: $showDeleteRoutineConfirmation
        )
    }

    // MARK: - View Builders

    private var deleteActionMenu: some View {
        Menu {
            deleteRoutineButton
        } label: {
            Label(
                "Delete Options",
                systemImage: "trash"
            )
        }
    }

    private var deleteRoutineButton: some View {
        Button(role: .destructive) {
            showDeleteRoutineConfirmation = true
        } label: {
            Text("Delete Routine")
        }
        .disabled(routineEvents.isEmpty)
    }

    // MARK: - Functions

    private func deleteRoutine() {
        modelContext.removeRoutineEventContextsFromRoutine(
            routineEventContexts: routineEvents,
            routine: routine,
            todayStartOfDay: todayService.todayPlanner.startOfDay(settings: settings),
            ekEventStore: calendarStore.ekEventStore,
        )
    }
}
