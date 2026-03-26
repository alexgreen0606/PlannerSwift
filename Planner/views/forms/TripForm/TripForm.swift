//
//  TripForm.swift
//  Planner
//
//  Created by Alex Green on 3/21/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct TripFormView: View {
    private let sourceTrip: Trip?
    private let settings: PlannerSettings
    private let onSave: (Trip) -> Void

    init(
        sourceTrip: Trip? = nil,
        settings: PlannerSettings,
        onSave: @escaping (Trip) -> Void
    ) {
        self.sourceTrip = sourceTrip
        self.settings = settings
        self.onSave = onSave

        var draftTrip = DraftTrip()
        if let sourceTrip {
            draftTrip.dateComponents = sourceTrip.dateComponents
            draftTrip.title = sourceTrip.title
            draftTrip.hideRoutines = sourceTrip.hideRoutines
            draftTrip.location = sourceTrip.location
        }

        self.draftTrip = draftTrip
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var trips: [Trip]

    @State private var draftTrip: DraftTrip
    @State private var showDeleteConfirmation = false
    @State private var showDateSelector: Bool = false
    @State private var existingTripDateComponents: Set<DateComponents> = []

    private var isNewTrip: Bool {
        sourceTrip == nil
    }

    private var canSave: Bool {
        !draftTrip.title.isEmpty
            && !draftTrip.dateComponents.isEmpty
            && dateErrorMessage == nil
    }

    private var dayCount: Int {
        draftTrip.dateComponents.count
    }

    private var dayCountLabel: String {
        "\(dayCount) day\(dayCount == 1 ? "" : "s")"
    }

    private var cancelMessage: String {
        guard let sourceTrip else {
            return ""
        }

        var message =
            "Events will not be affected. This action is irreversible."

        if sourceTrip.location != nil {
            message =
                "Planner locations will default to your home location. "
                + message
        }

        return message
    }

    private var dateErrorMessage: String? {
        let existing = Set(existingTripDateComponents.compactMap(\.datestamp))
        let draft = Set(draftTrip.dateComponents.compactMap(\.datestamp))

        guard
            let conflict = existing.intersection(draft).first,
            let invalidDay = DateInRegion(conflict, region: .local)
        else {
            return nil
        }

        return invalidDay.dynamicSentenceTitle
    }

    private var datesLabel: String {
        let datestamps = draftTrip.dateComponents.compactMap { $0.datestamp }
            .sorted()

        guard let firstDatestamp = datestamps.first,
            let firstDay = DateInRegion(firstDatestamp, region: .local)
        else {
            return "Select Dates"
        }

        guard let lastDatestamp = datestamps.last,
            let lastDay = DateInRegion(lastDatestamp, region: .local)
        else {
            return ""
        }

        if firstDatestamp == lastDatestamp {
            return firstDay.tripLabel
        }

        return "\(firstDay.tripLabel) - \(lastDay.tripLabel)"
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                dateSection
                routineSection
                cancelSection
            }
            .navigationTitle(isNewTrip ? "Create Trip" : "Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelButton
                saveButton
            }
        }
        .animation(.linear, value: showDateSelector)
        .animateSynchronousAction(from: dateErrorMessage)
        .tint(accentColor.color)
        .onAppear {
            buildExistingTripDates()

            if isNewTrip {
                showDateSelector = true
            }
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", systemImage: "xmark") {
                dismiss()
            }
            .tint(Color.label)
        }
    }

    @ToolbarContentBuilder
    private var saveButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save", systemImage: "checkmark", action: saveTrip)
                .buttonStyle(.glassProminent)
                .tint(canSave ? accentColor.color : .tertiary)
                .disabled(!canSave)
        }
    }

    // MARK: - View Builders

    private var titleSection: some View {
        Section {
            TextField("Title", text: $draftTrip.title)
                .textInputAutocapitalization(.words)
        }
    }

    private var dateSection: some View {
        Section {

            FormLabelView(systemImageName: "calendar", value: datesLabel) {
                showDateSelector.toggle()
            }
            .listRowSeparator(showDateSelector ? .hidden : .visible)

            if showDateSelector {
                VStack {
                    DateRangePickerView(
                        selectedDates: $draftTrip.dateComponents
                    )
                    HStack {
                        HStack(spacing: 4) {
                            Text("Duration:")
                                .font(.footnote)
                                .foregroundStyle(Color.secondary)

                            Text(dayCountLabel)
                                .font(
                                    .system(
                                        size: 14,
                                        weight: .black,
                                        design: .rounded
                                    )
                                )
                        }
                        Spacer()
                    }
                    .opacity(dayCount == 0 ? 0 : 1)
                }
                .listRowInsets(.top, 0)
            }
            
            NavigationLink {
                LocationSearchFormView(
                    title: "Edit Trip Location",
                    mode: .trip,
                    settings: settings,
                    initialLocation: draftTrip.location
                ) { location in
                    draftTrip.location = location
                }
            } label: {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(
                            draftTrip.location == nil
                                ? Color.secondary : accentColor.color,
                            Color.label
                        )
                    Text("")
                    Spacer()
                    Text(
                        draftTrip.location?.name ?? "Home Location"
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
        } footer: {
            if let dateErrorMessage {
                Text(
                    "You already have a trip planned for \(dateErrorMessage)."
                )
                .foregroundStyle(Color.red)
            }
        }
        .listSectionSeparator(.hidden)
    }

    private var routineSection: some View {
        Section {
            Toggle(isOn: $draftTrip.hideRoutines) {
                Label("Exclude Routines", systemImage: "repeat.badge.xmark")
                    .foregroundStyle(Color.label)
                    .imageScale(.medium)
            }
        }
    }

    @ViewBuilder
    private var cancelSection: some View {
        if !isNewTrip {
            Section {
                cancelTripButton
            }
            .discreetListItem()
        }
    }

    @ViewBuilder
    private var cancelTripButton: some View {
        ActionButtonView(
            label: "Cancel \(draftTrip.title) Trip",
            systemImage: "trash",
            color: Color.red,
            onTap: {
                showDeleteConfirmation = true
            }
        )
        .frame(maxWidth: .infinity)
        .confirmationDialog(
            "Cancel this trip?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(
                "Confirm",
                role: .destructive,
                action: cancelTrip
            )
        } message: {
            Text(cancelMessage)
        }
    }

    // MARK: - Functions

    private func saveTrip() {
        do {
            try modelContext.transaction {

                guard
                    let savedTrip = modelContext.saveTripChanges(
                        from: draftTrip,
                        to: sourceTrip
                    )
                else {
                    return
                }

                dismiss()
                onSave(savedTrip)
            }
        } catch {}
    }

    private func cancelTrip() {
        dismiss()
        if let trip = sourceTrip {
            modelContext.cancelTrip(trip)
        }
    }

    private func buildExistingTripDates() {
        for trip in trips where trip.id != sourceTrip?.id {
            existingTripDateComponents.formUnion(trip.dateComponents)
        }
    }

}
