//
//  PlannerActionMenu.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import SwiftData
import SwiftUI

struct PlannerActionMenuView: View {
    @Binding var showLocationSheet: Bool
    let planner: Planner
    let plannerItems: [PlannerItem]
    let hasVisibleEvents: Bool

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerItem>
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerService: PlannerService

    @State private var showDeleteCompletedConfirmation = false

    private var rawCompletedEvents: [PlannerItem] {
        plannerItems.filter { $0.isCompleted }
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
            todaystamp: todayService.todaystamp
        )
    }

    private var deleteCompletedConfig: ConfirmationConfig {
        bulkDeleteCompletedPlannerItemConfig(
            completedEventCount: rawCompletedEvents.count,
            dateLabel: dateLabel,
            hasCalendarAccess: calendarService.hasCalendarAccess == true,
            delete: deleteCompletedEvents
        )
    }

    // MARK: - Body

    var body: some View {
        Menu("", systemImage: "ellipsis") {
            CompletedVisibilityToggleView(
                showCompleted: planner.showCompleted,
                toggle: {
                    withAnimation {
                        planner.showCompleted.toggle()
                    }
                }
            )

            SelectItemsButtonView<PlannerItem>(
                itemsLabel: "Events",
                hasVisibleItem: hasVisibleEvents
            )

            editLocationButton
            toggleRoutineExclusionButton
            deleteActionsMenu
        }

        // MARK: Delete Completed Confirmation

        .withConfirmation(
            deleteCompletedConfig,
            isPresented: $showDeleteCompletedConfirmation
        )
    }

    // MARK: - View Builders

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
            action: toggleRoutineExclusion,
            label: {
                Label(
                    planner.safeExcludeRoutine
                        ? "Include Routine" : "Exclude Routine",
                    systemImage: planner.safeExcludeRoutine
                        ? "repeat" : "repeat.badge.xmark"
                )
            }
        )
    }

    // MARK: Delete Menu

    private var deleteActionsMenu: some View {
        Menu {
            deleteCompletedEventsButton
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
        .disabled(rawCompletedEvents.isEmpty)
    }

    // MARK: - Functions

    private func deleteCompletedEvents() {
        // Note: Don't pass the EKEventStore here.
        // Calendar events are meant to survive mass-deletion so users can look back on their calendar.
        modelContext.deletePlannerItems(rawCompletedEvents)
    }

    private func toggleRoutineExclusion() {
        modelContext.togglePlannerRoutineExclusion(
            for: planner,
            plannerService: plannerService
        )
    }
}
