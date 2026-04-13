//
//  SelectedRoutineEventActions.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftData
import SwiftUI

// Clean

struct SelectedRoutineEventActionsView: View {
    @Binding var showTransferSheet: Bool
    let weekday: Weekday
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var routineManager: ListManager<RoutineEvent>
    @EnvironmentObject private var calendarStore: CalendarStore

    @State private var showDeleteConfirmation = false

    var body: some View {
        Button("Delete", systemImage: "trash") {
            showDeleteConfirmation = true
        }
        .tint(Color.label)
        .disabled(routineManager.selectedItemIds.isEmpty)
        .confirmationDialog(
            "Delete selected recurring events?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible,
        ) {
            Button(
                "Remove from \(weekday.label)s",
                role: .confirm,
                action: deleteSelectedEventsFromWeekday
            )
            Button(
                "Delete everywhere",
                role: .destructive,
                action: deleteSelectedEventsEverywhere
            )
        } message: {
            Text(
                "Future occurrences will be deleted from your planner. Removing from \(weekday.label) will not affect other days. This action cannot be undone."
            )
        }
        Spacer()
        transferSelectedButton
    }

    // MARK: - View Builders

    private var transferSelectedButton: some View {
        Button(
            "Transfer",
            systemImage: "arrow.left.arrow.right"
        ) {
            showTransferSheet = true
        }
        .tint(Color.label)
        .disabled(routineManager.selectedItemIds.isEmpty)
        .matchedTransitionSource(
            id: IdConstants.TRANSFER_BUTTON,
            in: namespace
        )
    }

    // MARK: - Functions

    private func deleteSelectedEventsFromWeekday() {
        modelContext.deleteRoutineEvents(
            routineManager.selectedItems,
            from: weekday,
            ekEventStore: calendarStore.ekEventStore
        )

        DispatchQueue.main.async {
            routineManager.toggleSelectMode()
        }
    }

    private func deleteSelectedEventsEverywhere() {
        modelContext.deleteRoutineEvents(
            routineManager.selectedItems,
            ekEventStore: calendarStore.ekEventStore
        )

        DispatchQueue.main.async {
            routineManager.toggleSelectMode()
        }
    }

}
