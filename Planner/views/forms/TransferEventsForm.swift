//
//  TransferEventsForm.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftData
import SwiftUI

struct TransferEventsFormView: View {
    let sourceDate: Date

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject var plannerManager: ListManager<PlannerEvent>

    @State private var destinationDate: Date

    private var transferCount: String {
        let count = plannerManager.selectedItems.count
        return
            "\(count == 0 ? "No" : String(count)) event\(count == 1 ? "" : "s")"
    }

    init(sourcePlanner: Planner) {
        let initialDate = sourcePlanner.datestamp.date ?? Date()
        self.sourceDate = initialDate
        _destinationDate = State(initialValue: initialDate)
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
                    .listRowBackground(Color.clear)
                    .discreetListItem()
                }
                .discreetListItem()
                .listSectionMargins(.top, 0)
                .padding(.top, 0)

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
        .presentationDetents([.height(450)])
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Submit", systemImage: "checkmark", role: .confirm) {
                // TODO: transfer

                //                guard let destination, destination.id != source.id else {
                //                    return
                //                }
                //
                //                do {
                //                    try modelContext.transaction {
                //                        destination.inheritItems(plannerManager.selectedItems)
                //                    }
                //                } catch {
                //                    assertionFailure("Failed to transfer items: \(error)")
                //                    return
                //                }

                plannerManager.toggleSelectMode()

                dismiss()
            }
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
                    .foregroundStyle(Color(uiColor: .secondaryLabel))

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
            subtitle: sourceDate.dynamicHeader,
            iconConfig: IconConfig(
                name: "note",
                primaryColor: nil,
                secondaryColor: nil
            )
        )
    }

    private var destinationChip: some View {
        TransferDestinationIndicatorView(
            title: destinationDate.dynamicHeader,
            iconConfig: IconConfig(
                name: destinationDate.datestamp.calendarSymbolName,
                primaryColor: nil,
                secondaryColor: nil
            )
        )
    }

}
