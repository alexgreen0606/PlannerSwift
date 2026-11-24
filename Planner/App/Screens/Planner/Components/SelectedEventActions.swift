//
//  SelectedEventActions.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import SwiftData
import SwiftUI

struct SelectedEventActionsView: View {
    @Binding var showTransferSheet: Bool
    let planner: Planner
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerItem>

    private var deleteConfig: ConfirmationConfig {
        bulkDeletePlannerItemConfig(
            items: plannerEngine.selectedItems,
            delete: deleteSelectedEvents
        )
    }

    // MARK: - Body

    var body: some View {
        HStack {
            DeleteSelectedButtonView<PlannerItem>(
                confirmationConfig: deleteConfig
            )

            Spacer()

            TransferSelectedButtonView<PlannerItem>(
                showTransferSheet: $showTransferSheet,
                namespace: namespace
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Functions

    private func deleteSelectedEvents() {
        let selections = plannerEngine.selectedItems

        plannerEngine.clearSelections()

        DispatchQueue.main.async {
            modelContext.deletePlannerItems(
                selections,
                ekEventStore: calendarService.ekEventStore
            )

            DispatchQueue.main.async(execute: plannerEngine.toggleSelectMode)
        }
    }
}
