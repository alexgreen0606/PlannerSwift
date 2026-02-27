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
    @State private var hasCalendarEvents: Bool = false

    private var destinationDay: DateInRegion {
        DateInRegion(destinationDate, region: sourceStartOfDay.region)
    }

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
                    .environment(
                        \.timeZone,
                        sourceStartOfDay.region.timeZone
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

        let daysBetween = sourceStartOfDay.date.getInterval(
            toDate: destinationDay.date,
            component: .day
        )
        let days = Int(daysBetween).days

        modelContext.shiftPlannerEvents(
            plannerManager.selectedItems,
            days: days,
            settings: settings,
            eventStore: calendarStore.ekEventStore
        )

        calendarStore.loadFreshCache(
            hiddenCalendarIds: settings.hiddenCalendarIds
        )

        dismiss()

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(700)) {
            plannerManager.toggleSelectMode()
        }
    }

}
