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
    @State private var existingTripDateComponents: Set<DateComponents> = []

    private var isNewTrip: Bool {
        sourceTrip == nil
    }

    private var canSave: Bool {
        !draftTrip.title.isEmpty
            && !draftTrip.dateComponents.isEmpty
            && dateErrorMessage == nil
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

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                timeSection
                routineSection
                cancelSection
            }
            .navigationTitle(isNewTrip ? "Create Trip" : "Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDisabled(true)
            .toolbar {
                cancelButton
                saveButton
            }
        }
        .tint(accentColor.color)
        .onAppear {
            buildExistingTripDates()
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

            LabeledContent {
                NavigationLink {
                    LocationSearchFormView(
                        title: "Edit Event Location",
                        mode: .trip,
                        settings: settings,
                        initialLocation: draftTrip.location
                    ) { location in
                        draftTrip.location = location
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(
                            draftTrip.location?.name ?? "Home Location"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(
                            draftTrip.location == nil
                                ? Color.secondary : accentColor.color,
                            Color.label
                        )

                    Text("Location")
                }
            }
        }
    }

    private var timeSection: some View {
        Section {
            DateRangePickerView(
                selectedDates: $draftTrip.dateComponents
            )
        } footer: {
            if let dateErrorMessage {
                Text(
                    "You already have a trip planned for \(dateErrorMessage)."
                )
                .foregroundStyle(Color.red)
            }
        }
    }

    private var routineSection: some View {
        Section {
            Toggle(isOn: $draftTrip.hideRoutines) {
                Label("Exclude Routines", systemImage: "repeat.badge.xmark")
                    .foregroundStyle(Color.label)
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
