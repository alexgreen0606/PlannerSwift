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
        deleteSelectedButton
        Spacer()
        transferSelectedButton
    }

    // MARK: - View Builders

    private var deleteSelectedButton: some View {
        Button("Delete", systemImage: "trash") {
            showDeleteConfirmation = true
        }
        .tint(Color.label)
        .disabled(routineManager.selectedItemIds.isEmpty)
        .withConfirmation(
            bulkRemoveRoutineEventFromWeekdayConfig(
                events: routineManager.selectedItems,
                weekday: weekday,
                remove: deleteSelectedEventsFromWeekday,
                delete: deleteSelectedEventsEverywhere
            ),
            isPresented: $showDeleteConfirmation
        )
    }

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

        DispatchQueue.main.async(execute: routineManager.toggleSelectMode)
    }

    private func deleteSelectedEventsEverywhere() {
        modelContext.deleteRoutineEvents(
            routineManager.selectedItems,
            ekEventStore: calendarStore.ekEventStore
        )

        DispatchQueue.main.async(execute: routineManager.toggleSelectMode)
    }

}
