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

struct TransferEventsFormView: View {
    private let sourceDate: Date
    private let sourceStartOfDay: DateInRegion
    private let settings: PlannerSettings

    init(startOfDay: DateInRegion, settings: PlannerSettings) {
        self.sourceDate = startOfDay.date
        self.sourceStartOfDay = startOfDay
        self.settings = settings
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
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerManager: ListManager<PlannerEvent>

    @State private var destinationDate: Date

    private var destinationDay: DateInRegion {
        DateInRegion(destinationDate, region: sourceStartOfDay.region)
    }

    private var transferCount: String {
        let count = plannerManager.selectedItems.count
        return
            "\(count == 0 ? "No" : String(count)) event\(count == 1 ? "" : "s")"
    }

    private var dayOffset: Int {
        let daysBetween = sourceStartOfDay.date.getInterval(
            toDate: destinationDay.date,
            component: .day
        )
        return Int(daysBetween)
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
                        sourceStartOfDay.region.timeZone
                    )
                    .datePickerStyle(.graphical)
                    .discreetListItem()
                } header: {
                    HStack {
                        Spacer()
                        let absOffset = abs(dayOffset)
                        Text(
                            "\(absOffset) day\(absOffset == 1 ? "" : "s") \(dayOffset > 0 ? "later" : "earlier")"
                        )
                        .font(
                            .system(size: 12, weight: .bold, design: .rounded)
                        )
                        .foregroundStyle(Color.secondary)
                        .opacity(dayOffset == 0 ? 0 : 1)
                    }
                }
                .discreetListItem()
                .listSectionMargins(.top, 0)
            }
            .scrollDisabled(true)
            .navigationTitle(
                "Reschedule Plans"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                topRightToolbar
            }
            .safeAreaInset(edge: .top) {
                transferIndicator
            }
        }
        .presentationDetents([.height(500)])
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
            .tint(accentColor.value)
            .disabled(destinationDate == sourceDate)
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
        .animateSynchronousAction(from: destinationDate)
    }

    private var sourceChip: some View {
        TransferSourceIndicatorView(
            title: transferCount,
            subtitle: sourceStartOfDay.dynamicHeader,
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

    private func handleTransfer() {
        
        modelContext.transferPlannerEvents(
            plannerManager.selectedItems,
            days: dayOffset.days,
            previousDatestamp: sourceStartOfDay.datestamp,
            targetDatestamp: destinationDay.datestamp,
            settings: settings,
            eventStore: calendarStore.ekEventStore
        )

        calendarStore.attemptFreshReload(
            hiddenCalendarIds: settings.hiddenCalendarIds
        )

        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(700)) {
            plannerManager.toggleSelectMode()
        }
    }

}
