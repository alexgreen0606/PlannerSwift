//
//  TransferRoutineEventsForm.swift
//  Planner
//
//  Created by Alex Green on 4/8/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct TransferRoutineEventsFormView: View {
    let sourceDayOfWeek: Weekday
    let sortedSourceRoutineEvents: [RoutineEvent]
    let openRoutine: (Weekday) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.showToast) private var showToast
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var PlannerSyncStore: PlannerSyncStore
    @EnvironmentObject private var routineManager: ListStore<RoutineEvent>

    @State private var selectedDaysOfWeek: Set<Weekday> = []

    private var transferCount: String {
        let count = routineManager.selectedItems.count
        return
            "\(String(count)) recurring event\(count == 1 ? "" : "s")"
    }

    private var canSave: Bool {
        !selectedDaysOfWeek.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DayOfWeekPickerView(daysOfWeek: $selectedDaysOfWeek)
                } footer: {
                    Text(
                        "Events will only appear in the selected days."
                    )
                }
                .listSectionMargins(.top, 0)
                .discreetListItem()

            }
            .scrollDisabled(true)
            .navigationTitle("Reschedule Recurring Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                saveButton
            }
        }
        .presentationDetents([.height(180)])
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var saveButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(
                "Save",
                systemImage: "checkmark",
                action: handleTransfer
            )
            .tint(accentColor.color)
            .disabled(!canSave)
        }
    }

    // MARK: - Functions

    private func handleTransfer() {
        let affectedWeekdays =
            Set(routineManager.selectedItems.flatMap { $0.sortDateMap.keys })
            .union(selectedDaysOfWeek)

        PlannerSyncStore.invalidateRoutineDays(affectedWeekdays)

        modelContext.transferRoutineEvents(
            routineManager.selectedItems,
            to: selectedDaysOfWeek,
            sortedSourceEvents: sortedSourceRoutineEvents,
            sourceDayOfWeek: sourceDayOfWeek
        )

        dismiss()

        DispatchQueue.main.async(execute: routineManager.toggleSelectMode)

        showNotification()
    }

    private func showNotification() {
        let selectedDays = selectedDaysOfWeek
        let eventCount = routineManager.selectedItems.count

        let subtitle: String? = {
            if selectedDays.count > 1 {
                return nil
            }

            if let destinationDay = selectedDays.first?.rawValue
                .capitalized
            {
                return "\(destinationDay)s"
            }

            return ""
        }()
        
        let customSubtitle: AnyView? = {
            if selectedDays.count == 1 {
                return nil
            }
            return AnyView(WeekdaySpreadView(
                selected: selectedDays,
                scale: 0.66,
                spacing: 1,
                customAccentColor: Color.label
            ))
        }()

        let canOpenDestinationRoutine = {
            guard selectedDays.count == 1 else { return false }

            return selectedDays.first! != sourceDayOfWeek
        }()

        let onClick =
            canOpenDestinationRoutine
            ? {
                openRoutine(selectedDays.first!)
            } : nil

        showToast(
            Toast(
                title:
                    "Successfully moved \("recurring event".pluralized(from: eventCount))!",
                subtitle: subtitle,
                customSubtitle: customSubtitle,
                iconConfig: IconConfig(
                    name: "arrow.left.arrow.right",
                    primaryColor: Color.label,
                    secondaryColor: Color.label
                ),
                action: onClick
            )
        )
    }

}
