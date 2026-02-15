//
//  TransferEventsForm.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct TransferEventsFormView: View {
    private let sourceDate: Date
    private let sourceStartOfDay: DateInRegion
    private let plannerSettings: PlannerSettings

    init(startOfDay: DateInRegion, settings: PlannerSettings) {
        self.sourceDate = startOfDay.date
        self.sourceStartOfDay = startOfDay
        self.plannerSettings = settings
        _destinationDate = State(initialValue: startOfDay.date)
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var plannerManager: ListManager<PlannerEvent>

    @State private var destinationDate: Date
    @State private var hasCalendarEvents: Bool = false

    private var transferCount: String {
        let count = plannerManager.selectedItems.count
        return
            "\(count == 0 ? "No" : String(count)) event\(count == 1 ? "" : "s")"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Select a Destination",
                        selection: $destinationDate,
                        in: keepPastPlansDuration
                            .cutoffDate...todaystampWatcher
                            .maxCalendarDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .discreetListItem()
                } footer: {
                    if hasCalendarEvents {
                        Text(
                            "Calendar events will be moved to the selected date while keeping their original start and end times. Event duration will not change."
                        )
                    }
                }
                .discreetListItem()
                .listSectionMargins(.top, 0)
            }
            .scrollDisabled(true)
            .navigationTitle(
                "Transfer Events"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                topRightToolbar
            }
            .safeAreaInset(edge: .top) {
                transferIndicator
            }
        }
        .presentationDetents([.height(hasCalendarEvents ? 580 : 500)])

        .task {
            hasCalendarEvents = plannerManager.selectedItems.contains(where: {
                $0.calendarEvent != nil
            })
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(
                "Submit",
                systemImage: "checkmark",
                role: .confirm,
                action: handleTransfer
            )
            .disabled(destinationDate == sourceDate)
            .tint(accentColor.swiftUIColor)
        }
    }

    // MARK: - Transfer Indicator

    private var transferIndicator: some View {
        HStack(spacing: 16) {
            sourceChip

            if destinationDate != sourceDate {
                Image(systemName: "arrow.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.secondary)

                destinationChip
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .animateChange(from: destinationDate)
    }

    private var sourceChip: some View {
        TransferSourceIndicatorView(
            title: transferCount,
            subtitle: sourceStartOfDay.dynamicHeader,
            iconConfig: IconConfig(
                name: "note",
                primaryColor: nil,
                secondaryColor: nil
            )
        )
    }

    private var destinationChip: some View {
        TransferDestinationIndicatorView(
            title: "TODO", // destinationDate.dynamicHeader,
            iconConfig: IconConfig(
                name: "TODO", // destinationDate.datestamp.calendarSymbolName,
                primaryColor: nil,
                secondaryColor: nil
            )
        )
    }

    private func handleTransfer() {
        let targetDatestamp = "TODO"// destinationDate.datestamp
        let planner = modelContext.loadPlanner(for: targetDatestamp)

        var plannerEvents: [PlannerEvent] = []

        for event in plannerManager.selectedItems {
            if let calEvent = event.calendarEvent {

            } else {
                plannerEvents.append(event)
            }
        }
        
        // TODO: find the target startOfDay
        let targetStartOfDay = DateInRegion(Date(), region: .local)
        modelContext.transferPlannerEvents(plannerEvents, to: targetStartOfDay)

        plannerManager.toggleSelectMode()
        dismiss()
    }

}
