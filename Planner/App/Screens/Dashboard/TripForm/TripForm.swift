//
//  TripForm.swift
//  Planner
//
//  Created by Alex Green on 3/21/26.
//

import SwiftData
import SwiftUI

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
            draftTrip.title = sourceTrip.title
            draftTrip.selectedDates = sourceTrip.dateComponents
            draftTrip.location = sourceTrip.location
            draftTrip.excludeRoutines = sourceTrip.excludeRoutines
        }

        self._draftTrip = State(initialValue: draftTrip)
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var todaystampService: TodaystampService
    @EnvironmentObject private var plannerSyncService: PlannerSyncService

    @State private var draftTrip: DraftTrip

    @FocusState private var isTitleFocused
    @State private var hasTitleAutoFocused = false

    @State private var showDatePicker: Bool = false
    @State private var existingTripDatestamps: Set<String> = []

    @State private var showDeleteConfirmation = false

    private var isNewTrip: Bool {
        sourceTrip == nil
    }

    private var canSave: Bool {
        !draftTrip.title.trimmed.isEmpty
            && !draftTrip.selectedDates.isEmpty
            && datesError == nil
    }

    private var datesLabel: String {
        let sortedDatestamps = draftTrip.datestamps.sorted()

        guard let firstDatestamp = sortedDatestamps.first,
            let lastDatestamp = sortedDatestamps.last
        else {
            return "Select Dates"
        }

        return buildDateRangeLabel(
            firstDatestamp: firstDatestamp,
            lastDatestamp: lastDatestamp,
            todaystamp: todaystampService.todaystamp
        )
    }

    private var dayCountLabel: LocalizedStringKey {
        "^[\(draftTrip.selectedDates.count) day](inflect: true)"
    }

    private var datesError: String? {
        guard
            let dateConflict = existingTripDatestamps.intersection(
                draftTrip.datestamps
            ).first
        else {
            return nil
        }

        return
            "\(dateConflict.dateLabel(todaystamp: todaystampService.todaystamp)) is linked to a different trip."
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                detailsSection
                routineSection
            }
            .toolbar {
                cancelButton
                saveButton
                deleteTripButton
            }
            .navigationTitle("\(isNewTrip ? "Create" : "Edit") Trip")
            .navigationBarTitleDisplayMode(.inline)
        }
        .animation(.linear, value: showDatePicker)
        .animation(.linear, value: datesError)
        .tint(accentColor.color)
        .task {
            showDatePicker = isNewTrip

            var existingTripDatestamps =
                modelContext.getExistingTripDatestamps()

            if let sourceTrip {
                existingTripDatestamps = existingTripDatestamps.filter {
                    datestamp in
                    !sourceTrip.safePlanners.contains(where: {
                        $0.datestamp == datestamp
                    })
                }
            }

            self.existingTripDatestamps = existingTripDatestamps
        }

        // MARK: Blur the title field when another field is modified.

        .onChange(of: draftTrip.selectedDates) { _, _ in
            isTitleFocused = false
        }
        .onChange(of: draftTrip.excludeRoutines) { _, _ in
            isTitleFocused = false
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
    private var deleteTripButton: some ToolbarContent {
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
            datePicker
            locationField
        }
        .listSectionSeparator(.hidden)
    }

    private var datesField: some View {
        FormLabelView(
            systemImageName: "calendar",
            value: datesLabel,
            detail: dayCountLabel,
            color: datesError != nil ? Color.red : nil,
            onTap: {
                if !showDatePicker {
                    isTitleFocused = false
                }
                showDatePicker.toggle()
            }
        )
        .id("DATES_FIELD_\(datesError != nil)")
        .listRowSeparator(showDatePicker ? .hidden : .visible)
    }

    @ViewBuilder
    private var datePicker: some View {
        if showDatePicker {
            VStack {
                DateRangePickerView(
                    selectedDates: $draftTrip.selectedDates
                )

                if let datesError {
                    Text(datesError)
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
                title: "Trip Location",
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
            PlannerSyncStore: plannerSyncService
        )

        dismiss()
        onSave?(savedTrip)
    }

    private func deleteTrip() {
        dismiss()
        if let sourceTrip {
            modelContext.safeDelete(sourceTrip)
        }
    }
}
