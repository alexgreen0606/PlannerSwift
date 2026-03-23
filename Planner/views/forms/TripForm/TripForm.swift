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

// TODO: add delete option

struct TripFormView: View {
    private let sourceTrip: Trip?
    private let settings: PlannerSettings

    init(
        sourceTrip: Trip? = nil,
        settings: PlannerSettings
    ) {
        self.sourceTrip = sourceTrip
        self.settings = settings

        var draftTrip = DraftTrip()
        if let sourceTrip {
            draftTrip.selectedDates = getDateComponentRange(
                from: sourceTrip.startDatestamp,
                to: sourceTrip.endDatestamp
            )
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

    @State private var draftTrip: DraftTrip

    private var isCreateForm: Bool {
        sourceTrip == nil
    }

    private var canSave: Bool {
        !draftTrip.title.isEmpty && !draftTrip.selectedDates.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                timeSection
                routineSection
            }
            .navigationTitle(isCreateForm ? "Create Trip" : "Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDisabled(true)
            .toolbar {
                cancelButton
                saveButton
            }
        }
        .tint(accentColor.color)
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
                Label("Location", systemImage: "mappin.and.ellipse")
                    .foregroundStyle(Color.label)
            }
        }
    }

    private var timeSection: some View {
        Section {
            DateRangePickerView(
                selectedDates: $draftTrip.selectedDates
            )
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

    // MARK: - Functions

    // TODO: move to model context
    private func saveTrip() {

        guard let bounds = getDatestampBounds(from: draftTrip.selectedDates)
        else {
            return
        }

        let trip = sourceTrip ?? Trip()
        trip.title = draftTrip.title
        trip.startDatestamp = bounds.startDatestamp
        trip.endDatestamp = bounds.endDatestamp
        trip.hideRoutines = draftTrip.hideRoutines
        trip.location = draftTrip.location

        if trip.modelContext == nil {
            modelContext.insert(trip)
        }

        modelContext.safeSave("save trip")

        // update all the matching planners

        dismiss()

        // TODO: scroll to trip

    }

}
