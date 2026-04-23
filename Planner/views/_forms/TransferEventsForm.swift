//
//  TransferEventsForm.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct TransferEventsFormView: View {
    private let settings: PlannerSettings

    init(sourceStartOfDay: DateInRegion, settings: PlannerSettings) {
        self.settings = settings

        self.sourceDate = sourceStartOfDay.date
        self.sourceDatestamp = sourceStartOfDay.datestamp
        _destinationDate = State(initialValue: sourceStartOfDay.date)
    }

    private let sourceDate: Date
    private let sourceDatestamp: String

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            KeepPastEventsDuration.oneMonth

    @Environment(\.showToast) private var showToast
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerManager: ListManager<PlannerEvent>

    @State private var destinationDate: Date

    private var destinationDatestamp: String {
        destinationDate.datestamp
    }

    private var transferCount: String {
        let count = plannerManager.selectedItems.count
        return
            "\(String(count)) event\(count == 1 ? "" : "s")"
    }

    private var dayOffset: Int {
        Int(
            sourceDatestamp.daysUntil(destinationDatestamp) ?? 0
        )
    }

    private var offsetLabel: String {
        let absOffset = abs(dayOffset)
        return
            "\(absOffset) day\(absOffset == 1 ? "" : "s") \(dayOffset > 0 ? "later" : "earlier")"
    }

    private var canSave: Bool {
        destinationDatestamp != sourceDatestamp
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Select a Destination",
                        selection: $destinationDate,
                        in: keepPastEventsDuration
                            .cutoffDate...todaystampWatcher
                            .maxCalendarDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .discreetListItem()

                } header: {
                    offsetCountIndicator
                }
                .discreetListItem()
                .listSectionMargins(.top, 0)

            }
            .scrollDisabled(true)
            .navigationTitle("Reschedule Events")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                saveButton
            }
            .safeAreaInset(edge: .top) {
                transferIndicator
            }
        }
        .presentationDetents([.height(500)])
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

    // MARK: - View Builders

    private var transferIndicator: some View {
        HStack {
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
        .animateSynchronousAction(from: destinationDate)
    }

    private var sourceChip: some View {
        TransferSourceIndicatorView(
            title: transferCount,
            subtitle: sourceDatestamp.proximityFormat(
                using: [
                    ProximityRule(proximity: .next7Days, format: .weekday),
                    ProximityRule(
                        proximity: .fallback,
                        format: .dateLabel
                    ),
                ],
                todaystamp: todaystampWatcher.todaystamp
            ),
            iconConfig: IconConfig(
                name: "note"
            )
        )
    }

    private var destinationChip: some View {
        TransferDestinationIndicatorView(
            title: destinationDatestamp.proximityFormat(
                using: [
                    ProximityRule(proximity: .next7Days, format: .weekday),
                    ProximityRule(proximity: .fallback, format: .dateLabel),
                ],
                todaystamp: todaystampWatcher.todaystamp
            ),
            iconConfig: IconConfig(
                name: destinationDatestamp.calendarSymbolName
            )
        )
    }

    private var offsetCountIndicator: some View {
        HStack {
            Spacer()
            Text(offsetLabel)
                .font(
                    .system(size: 12, weight: .bold, design: .rounded)
                )
                .foregroundStyle(Color.secondary)
                .opacity(dayOffset == 0 ? 0 : 1)
        }
    }

    // MARK: - Functions

    private func handleTransfer() {

        let eventCount = plannerManager.selectedItems.count

        modelContext.shiftPlannerEvents(
            plannerManager.selectedItems,
            days: dayOffset.days,
            sourceDatestamp: sourceDatestamp,
            targetDatestamp: destinationDatestamp,
            settings: settings,
            eventStore: calendarStore.ekEventStore
        )

        plannerManager.toggleSelectMode()

        dismiss()

        let primaryColor = dayOffset > 0 ? Color.secondary : Color.label
        let secondaryColor = dayOffset > 0 ? Color.label : Color.secondary

        DispatchQueue.main.async {
            showToast(
                Toast(
                    title:
                        "Shifted \(eventCount) \("Event".pluralized(from: eventCount)) \(offsetLabel.capitalized)!",
                    iconConfig: IconConfig(
                        name: "arrow.left.arrow.right",
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor
                    )
                )
            )
        }
    }

}
