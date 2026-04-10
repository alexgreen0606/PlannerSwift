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

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var routineManager: ListManager<RoutineEvent>

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

        let eventCount = routineManager.selectedItems.count

        modelContext.transferRoutineEvents(
            routineManager.selectedItems,
            to: selectedDaysOfWeek,
            sortedSourceEvents: sortedSourceRoutineEvents,
            sourceDayOfWeek: sourceDayOfWeek
        )

        routineManager.toggleSelectMode()

        let selectedDays = selectedDaysOfWeek

        let destinations = {
            if selectedDays.count > 1 {
                return Weekday.allCases
                    .filter { selectedDays.contains($0) }
                    .map { $0.initial }
                    .joined()
            }

            if let destinationDay = selectedDays.first?.rawValue
                .capitalizedFirst
            {
                return "\(destinationDay)s"
            }

            return ""
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

        DispatchQueue.main.async {
            notificationManager.addNotification(
                NotificationConfig(
                    title:
                        "Moved \(eventCount) recurring event\(eventCount == 1 ? "" : "s")",
                    subtitle: "to \(destinations)",
                    iconConfig: IconConfig(
                        name: "checkmark",
                        primaryColor: Color.green
                    ),
                    onClick: onClick
                )
            )
        }
        
        dismiss()
    }

}
