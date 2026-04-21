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
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var plannerBuildManager: PlannerBuildManager

    @State private var showDeleteCompletedConfirmation = false
    @State private var showDeleteCanceledConfirmation = false

    private var completedEvents: [PlannerEvent] {
        plannerEvents.filter { $0.isCompleted }
    }

    private var canceledEvents: [PlannerEvent] {
        plannerEvents.filter { $0.isCanceled }
    }

    private var dateLabel: String {
        planner.datestamp.proximityFormat(
            using: [
                ProximityRule(
                    proximity: .withinADay,
                    format: .countdown,
                    ordinal: true
                ),
                ProximityRule(
                    proximity: .next7Days,
                    format: .weekday
                ),
                ProximityRule(
                    proximity: .fallback,
                    format: .dateLabel,
                    ordinal: true
                ),
            ],
            todaystamp: todaystampWatcher.todaystamp
        )
    }

    private var deleteCompletedConfig: ConfirmationConfig {
        bulkDeleteCompletedPlannerEventConfig(
            completedEvents: completedEvents,
            dateLabel: dateLabel,
            hasCalendarAccess: calendarStore.accessDenied == false,
            delete: deleteCompletedEvents
        )
    }

    private var deleteCanceledConfig: ConfirmationConfig {
        deleteCanceledEventsConfig(
            canceledEvents: canceledEvents,
            dateLabel: dateLabel,
            hasCalendarAccess: calendarStore.accessDenied == false,
            delete: deleteCompletedEvents
        )
    }

    // MARK: - Body

    var body: some View {
        Menu("Planner Action Menu", systemImage: "ellipsis") {
            showCheckedToggle
            selectEventsButton
            editLocationButton
            toggleRoutineExclusionButton
            deleteActionsMenu
        }

        // MARK: Delete Completed Confirmation
        .withConfirmation(
            deleteCompletedConfig,
            isPresented: $showDeleteCompletedConfirmation
        )

        // MARK: Delete Canceled Confirmation
        .withConfirmation(
            deleteCanceledConfig,
            isPresented: $showDeleteCanceledConfirmation
        )
    }

    // MARK: - View Builders

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
                "Select Events",
                systemImage: "checkmark.circle"
            )
        }
        .disabled(visibleEvents.isEmpty)
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

    private var toggleRoutineExclusionButton: some View {
        Button(
            action: {
                modelContext.togglePlannerRoutineExclusion(
                    for: planner,
                    plannerEvents: plannerEvents
                )

                if !planner.safeExcludeRoutine,
                    let weekday = Weekday.forDatestamp(planner.datestamp)
                {
                    plannerBuildManager.invalidateRoutineDays([weekday])
                    plannerBuildManager.beginRebuild()
                }
            },
            label: {
                Label(
                    planner.safeExcludeRoutine
                        ? "Include Routine" : "Exclude Routine",
                    systemImage: planner.safeExcludeRoutine
                        ? "repeat" : "repeat.badge.xmark",
                )
            }
        )
    }

    // MARK: Delete Menu

    private var deleteActionsMenu: some View {
        Menu {
            deleteCompletedEventsButton
            deleteCanceledEventsButton
        } label: {
            Label(
                "Delete Options",
                systemImage: "trash"
            )
        }
    }

    private var deleteCompletedEventsButton: some View {
        Button("Delete Completed", role: .destructive) {
            showDeleteCompletedConfirmation = true
        }
        .disabled(completedEvents.isEmpty)
    }

    private var deleteCanceledEventsButton: some View {
        Button("Delete Canceled", role: .destructive) {
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
