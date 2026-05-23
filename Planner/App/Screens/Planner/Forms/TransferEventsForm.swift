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
    private let settings: PlannerSettings

    init(sourceStartOfDay: DateInRegion, settings: PlannerSettings) {
        self.settings = settings

        _destinationDate = State(initialValue: sourceStartOfDay.date)

        self.sourceRegion = sourceStartOfDay.region
        self.sourceDatestamp = sourceStartOfDay.datestamp
    }

    private let sourceDatestamp: String
    private let sourceRegion: Region

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.showToast) private var showToast
    @EnvironmentObject private var todaystampService: TodaystampService
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerEvent>
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    @State private var destinationDate: Date

    private var canSave: Bool {
        destinationDatestamp != sourceDatestamp
    }

    private var destinationDatestamp: String {
        destinationDate.datestamp(in: sourceRegion)
    }

    private var transferCount: LocalizedStringKey {
        "^[\(plannerEngine.selectedItems.count) event](inflect: true)"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "",
                        selection: $destinationDate,
                        in: todaystampService.datePickerBounds,
                        displayedComponents: .date
                    )
                    .environment(\.timeZone, sourceRegion.timeZone)
                    .datePickerStyle(.graphical)
                    .tint(accentColor.color)
                    .listRowInsets(.top, 0)
                    .discreetListItem()
                }
                .listSectionMargins(.top, 0)
                .discreetListItem()
            }
            .scrollDisabled(true)
            .safeAreaInset(edge: .top) {
                transferIndicator
            }
            .toolbar {
                FormSaveButtonView(canSave: canSave, save: transferEvents)
            }
            .navigationTitle("Transfer Events")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(450)])
    }

    // MARK: - View Builders

    private var transferIndicator: some View {
        HStack {
            if destinationDatestamp < sourceDatestamp {
                destinationChip
                transferDirectionArrow("arrow.left")
            }

            sourceChip

            if destinationDatestamp > sourceDatestamp {
                transferDirectionArrow("arrow.right")
                destinationChip
            }
        }
        .animateSynchronousAction(from: destinationDate)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    private var sourceChip: some View {
        TransferSourceIndicatorView(
            title: sourceDatestamp.dateLabel(
                todaystamp: todaystampService.todaystamp
            ),
            subtitle: transferCount
        )
    }

    private var destinationChip: some View {
        TransferDestinationIndicatorView(
            title: destinationDatestamp.dateLabel(
                todaystamp: todaystampService.todaystamp
            )
        )
    }

    private func transferDirectionArrow(_ systemImageName: String)
        -> some View
    {
        Image(systemName: systemImageName)
            .font(.system(size: 14))
            .foregroundStyle(Color.secondary)
    }

    // MARK: - Functions

    private func transferEvents() {
        guard let dayOffset = sourceDatestamp.daysUntil(destinationDatestamp),
            dayOffset != 0
        else {
            return
        }

        modelContext.shiftPlannerEvents(
            plannerEngine.selectedItems,
            days: dayOffset.days,
            sourceDatestamp: sourceDatestamp,
            targetDatestamp: destinationDatestamp,
            settings: settings,
            eventStore: calendarStore.ekEventStore
        )

        dismiss()

        DispatchQueue.main.async {
            let eventCount = plannerEngine.selectedItems.count

            plannerEngine.toggleSelectMode()

            DispatchQueue.main.async {
                showNotification(eventCount: eventCount, dayOffset: dayOffset)
            }
        }
    }

    private func showNotification(eventCount: Int, dayOffset: Int) {
        showToast(
            Toast(
                title:
                    "Successfully transferred ^[\(eventCount) event](inflect: true)!",
                subtitle: LocalizedStringKey(
                    destinationDatestamp.dateLabel(
                        todaystamp: todaystampService.todaystamp
                    )
                ),
                iconConfig: IconConfig(
                    name: "arrow.left.arrow.right",
                    primaryColor: dayOffset > 0
                        ? Color.secondary : Color.label,
                    secondaryColor: dayOffset > 0
                        ? Color.label : Color.secondary
                ),
                action: {
                    plannerCoverStore.context = PlannerCoverContext(
                        datestamp: destinationDatestamp
                    )
                }
            )
        )
    }
}
