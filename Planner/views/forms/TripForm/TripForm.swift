//
//  TripForm.swift
//  Planner
//
//  Created by Alex Green on 3/21/26.
//

import EventKit
import SwiftDate
import SwiftUI
import SwiftData

// TODO: add delete option

// TODO: get zoom animation working

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

            if let startDate = DateInRegion(
                sourceTrip.startDatestamp,
                region: .local
            )?.date {
                draftTrip.startDate = startDate
            }

            if let endDate = DateInRegion(
                sourceTrip.endDatestamp,
                region: .local
            )?.date {
                draftTrip.endDate = endDate
            }

            draftTrip.title = sourceTrip.title
            draftTrip.hideRoutines = sourceTrip.hideRoutines
            draftTrip.location = sourceTrip.location
        }

        self.draftTrip = draftTrip
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            KeepPastEventsDuration.oneMonth

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher

    @State private var draftTrip: DraftTrip

    private var isCreateForm: Bool {
        sourceTrip == nil
    }

    private var canSave: Bool {
        !draftTrip.title.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                timeSection
                locationSection
                routineSection
            }
            .navigationTitle(isCreateForm ? "Create Trip" : "Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDisabled(true)
            .toolbar {
                saveButton
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents(
            [.height(480), .large]
        )
        .tint(accentColor.color)
    }

    // MARK: - Toolbars

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
        .listSectionMargins(.top, 0)
    }

    // TODO: use a multi date picker
    private var timeSection: some View {
        Section {
            DatePicker(
                "Start",
                selection: $draftTrip.startDate,
                in: keepPastEventsDuration
                    .cutoffDate...todaystampWatcher
                    .maxCalendarDate,
                displayedComponents: .date
            )
            

            DatePicker(
                "End",
                selection: $draftTrip.endDate,
                in: keepPastEventsDuration
                    .cutoffDate...todaystampWatcher
                    .maxCalendarDate,
                displayedComponents: .date
            )
        }
    }

    private var locationSection: some View {
        Section {
            LabeledContent {
                NavigationLink {
                    LocationSearchFormView(
                        title: "Edit Event Location",
                        mode: .event,
                        settings: settings,
                        initialLocation: draftTrip.location
                    ) { location in
                        draftTrip.location = location
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(
                            draftTrip.location != nil
                                ? draftTrip.location!.name
                                : "Set a location"
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

    private var routineSection: some View {
        Section {
            Toggle(isOn: $draftTrip.hideRoutines) {
                Label("Exclude Routines", systemImage: "repeat.badge.xmark")
                    .foregroundStyle(Color.label)
            }
        }
    }

    // MARK: - Functions

    private func saveTrip() {
        
        let trip = sourceTrip ?? Trip()
        trip.title = draftTrip.title
        trip.startDatestamp = DateInRegion(draftTrip.startDate, region: .local).datestamp
        trip.endDatestamp = DateInRegion(draftTrip.endDate, region: .local).datestamp
        trip.hideRoutines = draftTrip.hideRoutines
        trip.location = draftTrip.location
        
        if trip.modelContext == nil {
            modelContext.insert(trip)
        }
        
        modelContext.safeSave("save trip")

        // TODO: save trip to store

        // update all the matching planners

        dismiss()

        // TODO: scroll to trip

    }

}
