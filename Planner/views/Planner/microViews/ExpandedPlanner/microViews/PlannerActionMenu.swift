//
//  PlannerActionMenu.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import SwiftUI

// Clean

struct PlannerActionMenuView: View {
    let plannerType: PlannerType
    let planner: Planner
    let showChecked: Bool
    let plannerEvents: [PlannerEvent]
    let visibleEvents: [PlannerEvent]

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var plannerManager: ListManager<PlannerEvent>

    @State private var showDeleteCheckedConfirmation = false

    private var checkedEvents: [PlannerEvent] {
        plannerEvents.filter { $0.isChecked }
    }

    var body: some View {
        Menu("Planner Action Menu", systemImage: "ellipsis") {
            showCheckedToggle
            selectEventsButton
            deleteActionsMenu
        }
        .confirmationDialog(
            plannerType.deleteCheckedConfirmationTitle,
            isPresented: $showDeleteCheckedConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Confirm",
                role: .destructive,
                action: deleteAllCheckedEvents
            )
        } message: {
            Text(
                "Calendar events will not be deleted. This action is irreversible."
            )
        }
    }

    // MARK: - View Builders

    private var showCheckedToggle: some View {
        Button(
            action: {
                plannerType == .future
                    ? planner.showCanceled.toggle()
                    : planner.showCompleted.toggle()
            },
            label: {
                Label(
                    plannerType.toggleCheckedLabel(
                        showChecked
                    ),
                    systemImage: showChecked
                        ? "eye.slash" : "eye"
                )
            }
        )
    }

    private var selectEventsButton: some View {
        Button {
            plannerManager.toggleSelectMode()
        } label: {
            Label(
                "Select events",
                systemImage: "checkmark.circle"
            )
        }
        .disabled(visibleEvents.isEmpty)
    }

    private var deleteActionsMenu: some View {
        Menu {
            deleteCheckedEventsButton
        } label: {
            Label(
                "Delete options",
                systemImage: "trash"
            )
        }
    }

    private var deleteCheckedEventsButton: some View {
        Button(plannerType.deleteCheckedLabel, role: .destructive) {
            showDeleteCheckedConfirmation = true
        }
        .disabled(checkedEvents.isEmpty)
    }

    // MARK: - Functions

    private func deleteAllCheckedEvents() {
        // Note: Don't pass the EKEventStore here.
        // Calendar events are meant to survive mass-deletion so users can look back on their calendar.
        modelContext.deletePlannerEvents(checkedEvents)
    }

}
