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
import SwiftUIIntrospect

struct TripFormView: View {
    private let sourceTrip: Trip?
    private let settings: PlannerSettings
    private let onSave: ((Trip) -> Void)?

    init(
        sourceTrip: Trip? = nil,
        settings: PlannerSettings,
        onSave: ((Trip) -> Void)? = nil
    ) {
        self.sourceTrip = sourceTrip
        self.settings = settings
        self.onSave = onSave

        var draftTrip = DraftTrip()
        if let sourceTrip {
            draftTrip.dateComponents = sourceTrip.dateComponents
            draftTrip.title = sourceTrip.title
            draftTrip.excludeRoutines = sourceTrip.excludeRoutines
            draftTrip.location = sourceTrip.location
        }

        self.draftTrip = draftTrip
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var TodaystampService: TodaystampService
    @EnvironmentObject private var PlannerSyncStore: PlannerSyncStore

    @Query private var trips: [Trip]

    @State private var draftTrip: DraftTrip
    @State private var showDeleteConfirmation = false
    @State private var showDatesPicker: Bool = false
    @State private var hasAutoFocused: Bool = false
    @State private var existingTripDateComponents: Set<DateComponents> = []
    @State private var hasTitleAutoFocused = false

    @FocusState private var isTitleFocused

    private var isNewTrip: Bool {
        sourceTrip == nil
    }

    private var canSave: Bool {
        !draftTrip.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
            && !draftTrip.dateComponents.isEmpty
            && invalidDayMessage == nil
    }

    private var dayCount: Int {
        draftTrip.dateComponents.count
    }

    private var dayCountLabel: String {
        "\(dayCount) day\(dayCount == 1 ? "" : "s")"
    }

    private var invalidDayMessage: String? {
        let existing = Set(existingTripDateComponents.compactMap(\.datestamp))
        let draft = Set(draftTrip.dateComponents.compactMap(\.datestamp))

        guard
            let conflict = existing.intersection(draft).first
        else {
            return nil
        }

        let formatted = conflict.proximityFormat(
            using: [
                ProximityRule(proximity: .withinADay, format: .countdown),
                ProximityRule(
                    proximity: .next7Days,
                    format: .weekday
                ),
                ProximityRule(
                    proximity: .fallback,
                    format: .dateLabel,
                    ordinal: true
                ),
            ],
            todaystamp: TodaystampService.todaystamp
        )

        return
            "\(formatted) is linked to a different trip."
    }

    private var datesLabel: String {
        draftTrip.dateRangeLabel(todaystamp: TodaystampService.todaystamp)
            ?? "Select Dates"
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                detailsSection
                routineSection
            }
            .navigationTitle(isNewTrip ? "Create Trip" : "Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelButton
                saveButton
                cancelTripButton
            }
        }
        .animation(.linear, value: showDatesPicker)
        .animation(.linear, value: invalidDayMessage)
        .tint(accentColor.color)
        .task {
            buildExistingTripDates()

            if isNewTrip {
                showDatesPicker = true
            }
        }

        // Blur the title field when another field is modified.
        .onChange(of: draftTrip.dateComponents) { _, _ in
            if isTitleFocused {
                isTitleFocused = false
            }
        }
        .onChange(of: draftTrip.excludeRoutines) { _, _ in
            if isTitleFocused {
                isTitleFocused = false
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

    @ToolbarContentBuilder
    private var cancelTripButton: some ToolbarContent {
        if let sourceTrip {
            ToolbarItem(placement: .bottomBar) {
                ActionButtonView(
                    label: "Delete Trip",
                    systemImage: "trash",
                    color: Color.red,
                    onTap: {
                        showDeleteConfirmation = true
                    }
                )
                .withConfirmation(
                    deleteTripConfig(trip: sourceTrip, delete: deleteTrip),
                    isPresented: $showDeleteConfirmation
                )
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    // MARK: - View Builders

    // MARK: Title

    private var titleSection: some View {
        FormTitleFieldView(
            text: $draftTrip.title,
            hasAutoFocused: $hasTitleAutoFocused,
            isFocused: $isTitleFocused
        )
        .textInputAutocapitalization(.words)
    }

    // MARK: Dates and Location

    private var detailsSection: some View {
        Section {
            datesField
            datesPicker
            locationField
        }
        .listSectionSeparator(.hidden)
    }

    private var datesField: some View {
        FormLabelView(
            systemImageName: "calendar",
            value: datesLabel,
            detail: dayCountLabel,
            color: invalidDayMessage != nil ? Color.red : nil
        ) {
            if !showDatesPicker {
                isTitleFocused = false
            }
            showDatesPicker.toggle()
        }
        .id("DATES_FIELD_\(invalidDayMessage != nil)")
        .listRowSeparator(showDatesPicker ? .hidden : .visible)
    }

    @ViewBuilder
    private var datesPicker: some View {
        if showDatesPicker {
            VStack {
                DateRangePickerView(
                    selectedDates: $draftTrip.dateComponents
                )

                if let invalidDayMessage {
                    Text(invalidDayMessage)
                        .font(.footnote)
                        .foregroundStyle(Color.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .listRowInsets(.top, 0)
        }
    }

    private var locationField: some View {
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
    }

    // MARK: Routines

    private var routineSection: some View {
        Section {
            Toggle(isOn: $draftTrip.excludeRoutines) {
                Label("Exclude Routines", systemImage: "repeat.badge.xmark")
                    .foregroundStyle(Color.label)
                    .imageScale(.medium)
            }
        }
    }

    // MARK: - Functions

    private func saveTrip() {
        let savedTrip = modelContext.updateTrip(
            from: draftTrip,
            to: sourceTrip,
            PlannerSyncStore: PlannerSyncStore
        )

        dismiss()
        onSave?(savedTrip)
    }

    private func deleteTrip() {
        dismiss()
        
        guard let trip = sourceTrip else { return }

        modelContext.safeDelete(trip)
    }

    private func buildExistingTripDates() {
        for trip in trips where trip.id != sourceTrip?.id {
            existingTripDateComponents.formUnion(trip.dateComponents)
        }
    }

}
