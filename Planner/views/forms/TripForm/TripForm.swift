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
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher

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
        !draftTrip.title.isEmpty
            && !draftTrip.dateComponents.isEmpty
            && invalidDayMessage == nil
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
                "Planner locations will reset to your home location. "
                + message
        }

        return message
    }

    private var invalidDayMessage: String? {
        let existing = Set(existingTripDateComponents.compactMap(\.datestamp))
        let draft = Set(draftTrip.dateComponents.compactMap(\.datestamp))

        guard
            let conflict = existing.intersection(draft).first,
            let invalidDay = DateInRegion(conflict, region: .local)
        else {
            return nil
        }

        let formatted = invalidDay.proximityFormat(
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
                )
            ]
        )

        return
            "\(formatted) is linked to a different trip."
    }

    private var datesLabel: String {
        draftTrip.dateRangeLabel ?? "Select Dates"
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
        .onAppear {
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
        .onChange(of: draftTrip.hideRoutines) { _, _ in
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
        if !isNewTrip {
            ToolbarItem(placement: .bottomBar) {
                ActionButtonView(
                    label: "Cancel Trip",
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
            Toggle(isOn: $draftTrip.hideRoutines) {
                Label("Exclude Routines", systemImage: "repeat.badge.xmark")
                    .foregroundStyle(Color.label)
                    .imageScale(.medium)
            }
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
