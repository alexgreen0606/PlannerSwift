//
//  PlannerActionMenu.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import SwiftData
import SwiftUI

// Clean

struct PlannerActionMenuView: View {
    @Binding var showLocationSheet: Bool
    let plannerType: PlannerType
    let planner: Planner
    let showChecked: Bool
    let plannerEvents: [PlannerEvent]
    let visibleEvents: [PlannerEvent]

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var plannerManager: ListManager<PlannerEvent>
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerBuildManager: PlannerBuildManager

    @State private var showDeleteCompletedConfirmation = false
    @State private var showDeleteCanceledConfirmation = false

    private var completedEvents: [PlannerEvent] {
        plannerEvents.filter { $0.isCompleted }
    }

    private var canceledEvents: [PlannerEvent] {
        plannerEvents.filter { $0.isCanceled }
    }

    var body: some View {
        Menu("Planner Action Menu", systemImage: "ellipsis") {
            selectEventsButton
            showCheckedToggle
            editLocationButton
            toggleRoutineExclusionButton
            deleteActionsMenu
        }

        .confirmationDialog(
            "Delete completed events from this planner?",
            isPresented: $showDeleteCompletedConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Confirm",
                role: .destructive,
                action: deleteCompletedEvents
            )
        } message: {
            Text(
                "Calendar events will not be deleted. This action is irreversible."
            )
        }

        .confirmationDialog(
            "Delete canceled events from this planner?",
            isPresented: $showDeleteCanceledConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Confirm",
                role: .destructive,
                action: deleteCanceledEvents
            )
        } message: {
            Text(
                "Calendar events will not be deleted. This action is irreversible."
            )
        }
    }

    // MARK: - View Builders

    private var toggleRoutineExclusionButton: some View {
        Button(
            action: {
                modelContext.togglePlannerRoutineExclusion(
                    for: planner,
                    plannerEvents: plannerEvents
                )

                if !planner.finalExcludeRoutine,
                    let weekday = Weekday.from(planner.datestamp.weekday)
                {
                    plannerBuildManager.invalidateRoutineDays([weekday])
                    plannerBuildManager.beginRebuild()
                }
            },
            label: {
                Label(
                    planner.finalExcludeRoutine
                        ? "Include Routine" : "Exclude Routine",
                    systemImage: planner.finalExcludeRoutine
                        ? "repeat" : "repeat.badge.xmark",
                )
            }
        )
    }

    private var editLocationButton: some View {
        Button(
            action: {
                showLocationSheet = true
            },
            label: {
                Label(
                    "Edit Location",
                    systemImage: "mappin.and.ellipse"
                )
            }
        )
    }

    private var showCheckedToggle: some View {
        Button(
            action: {
                planner.showChecked.toggle()
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
            deleteCompletedEventsButton
            deleteCanceledEventsButton
        } label: {
            Label(
                "Delete options",
                systemImage: "trash"
            )
        }
    }

    private var deleteCompletedEventsButton: some View {
        Button("Delete completed", role: .destructive) {
            showDeleteCompletedConfirmation = true
        }
        .disabled(completedEvents.isEmpty)
    }

    private var deleteCanceledEventsButton: some View {
        Button("Delete canceled", role: .destructive) {
            showDeleteCanceledConfirmation = true
        }
        .disabled(canceledEvents.isEmpty)
    }

    // MARK: - Functions

    private func deleteCompletedEvents() {
        // Note: Don't pass the EKEventStore here.
        // Calendar events are meant to survive mass-deletion so users can look back on their calendar.
        modelContext.deletePlannerEvents(completedEvents, in: planner)
    }

    private func deleteCanceledEvents() {
        // Note: Don't pass the EKEventStore here.
        // Calendar events are meant to survive mass-deletion so users can look back on their calendar.
        modelContext.deletePlannerEvents(canceledEvents, in: planner)
    }

}
