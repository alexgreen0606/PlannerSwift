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
    private let sourceDate: Date
    private let sourceDay: DateInRegion
    private let settings: PlannerSettings

    init(startOfDay: DateInRegion, settings: PlannerSettings) {
        self.sourceDate = startOfDay.date
        self.sourceDay = startOfDay
        self.settings = settings

        _destinationDate = State(initialValue: startOfDay.date)
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var plannerManager: ListManager<PlannerEvent>

    @State private var destinationDate: Date

    private var destinationDay: DateInRegion {
        DateInRegion(destinationDate, region: sourceDay.region)
    }

    private var transferCount: String {
        let count = plannerManager.selectedItems.count
        return
            "\(String(count)) event\(count == 1 ? "" : "s")"
    }

    private var dayOffset: Int {
        Int(
            dayDifference(
                from: sourceDay.datestamp,
                to: destinationDay.datestamp
            ) ?? 0
        )
    }

    private var offsetLabel: String {
        let absOffset = abs(dayOffset)
        return
            "\(absOffset) day\(absOffset == 1 ? "" : "s") \(dayOffset > 0 ? "later" : "earlier")"
    }

    private var canSave: Bool {
        destinationDay != sourceDay
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
                    .environment(
                        \.timeZone,
                        sourceDay.region.timeZone
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
            subtitle: sourceDay.dynamicHeader,
            iconConfig: IconConfig(
                name: "note"
            )
        )
    }

    private var destinationChip: some View {
        TransferDestinationIndicatorView(
            title: destinationDay.dynamicHeader,
            iconConfig: IconConfig(
                name: destinationDay.datestamp.calendarSymbolName
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

        modelContext.transferPlannerEvents(
            plannerManager.selectedItems,
            days: dayOffset.days,
            sourceDay: sourceDay,
            targetDatestamp: destinationDay.datestamp,
            settings: settings,
            eventStore: calendarStore.ekEventStore
        )

        plannerManager.toggleSelectMode()

        dismiss()

        DispatchQueue.main.async {
            notificationManager.addNotification(
                NotificationConfig(
                    id: UUID(),
                    title:
                        "Rescheduled \(eventCount) event\(eventCount == 1 ? "" : "s")",
                    subtitle: offsetLabel,
                    iconConfig: IconConfig(
                        name: "checkmark",
                        primaryColor: Color.green
                    )
                )
            )
        }
    }

}
