//
//  RoutineEventForm.swift
//  Planner
//
//  Created by Alex Green on 4/6/26.
//

import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct DraftRoutineEvent {
    var date: Date
    var hasTime: Bool
    var title: String
    var daysOfWeek: Set<Weekday>
}

struct RoutineEventFormView: View {
    private let sourceRoutineEvent: RoutineEvent?
    private let sourceDayOfWeek: Weekday?
    private let sortedSourceEvents: [RoutineEvent]?
    private let openRoutine: (Weekday) -> Void

    init(
        sourceRoutineEvent: RoutineEvent? = nil,
        sourceDayOfWeek: Weekday? = nil,
        sortedSourceEvents: [RoutineEvent]? = nil,
        openRoutine: @escaping (Weekday) -> Void
    ) {
        self.sourceRoutineEvent = sourceRoutineEvent
        self.sourceDayOfWeek = sourceDayOfWeek
        self.sortedSourceEvents = sortedSourceEvents
        self.openRoutine = openRoutine

        let daysOfWeek: Set<Weekday> = sourceRoutineEvent?.weekdays ?? []

        let time = {
            if let existingTime = sourceRoutineEvent?.time {
                return existingTime
            }

            let now = Date()
            let hour = Calendar.current.component(.hour, from: now)

            var components = DateComponents()
            components.year = 2000
            components.month = 6
            components.day = 6
            components.hour = hour

            var utcCalendar = Calendar(identifier: .gregorian)
            utcCalendar.timeZone = TimeZone(identifier: "UTC")!

            // Default to now, rounded down to the start of the hour.
            return utcCalendar.date(from: components)!
        }()

        self._draftRoutineEvent = State(
            initialValue: DraftRoutineEvent(
                date: time,
                hasTime: sourceRoutineEvent?.time != nil,
                title: sourceRoutineEvent?.title ?? "",
                daysOfWeek: daysOfWeek
            )
        )
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.showToast) private var showToast
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var PlannerSyncStore: PlannerSyncStore

    @State private var draftRoutineEvent: DraftRoutineEvent

    @State private var showDeleteConfirmation = false
    @State private var showTimePicker = false
    @State private var hasTitleAutoFocused = false

    @FocusState private var isTitleFocused

    private var isCreateForm: Bool {
        sourceRoutineEvent == nil
    }

    private var canSave: Bool {
        !draftRoutineEvent.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
            && !draftRoutineEvent.daysOfWeek.isEmpty
    }

    private var timeAndDay: DateInRegion? {
        guard draftRoutineEvent.hasTime else {
            return nil
        }
        return DateInRegion(draftRoutineEvent.date, region: .UTC)
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                daysSection
                detailsSection
            }
            .animation(.linear, value: showTimePicker)
            .navigationTitle(
                isCreateForm ? "Create Recurring Event" : "Edit Recurring Event"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelButton
                saveButton
                deleteButton
            }
        }
        .onChange(of: draftRoutineEvent.daysOfWeek) { _, _ in
            ensureTextfieldBlurred()
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", systemImage: "xmark") {
                isTitleFocused = false
                dismiss()
            }
            .foregroundStyle(Color.label)
            .tint(Color.label)
        }
    }

    @ToolbarContentBuilder
    private var saveButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save", systemImage: "checkmark", action: saveRoutineEvent)
                .buttonStyle(.glassProminent)
                .tint(canSave ? accentColor.color : .tertiary)
                .disabled(!canSave)
        }
    }

    @ToolbarContentBuilder
    private var deleteButton: some ToolbarContent {
        if !isCreateForm {
            ToolbarItem(placement: .bottomBar) {
                ActionButtonView(
                    label: "Delete Recurring Event",
                    systemImage: "trash",
                    color: Color.red,
                    onTap: {
                        showDeleteConfirmation = true
                    }
                )
                .withConfirmation(
                    deleteRoutineEventConfig(
                        event: sourceRoutineEvent!,
                        inForm: true,
                        delete: deleteEvent
                    ),
                    isPresented: $showDeleteConfirmation
                )
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    // MARK: - View Builders

    private var titleSection: some View {
        FormTitleFieldView(
            text: $draftRoutineEvent.title,
            hasAutoFocused: $hasTitleAutoFocused,
            isFocused: $isTitleFocused
        )
    }

    private var detailsSection: some View {
        Section {
            timeField
            timePicker
        }
        .listSectionSeparator(.hidden)
        .environment(\.timeZone, .gmt)
    }

    @ViewBuilder
    private var daysSection: some View {
        Section {
            DayOfWeekPickerView(daysOfWeek: $draftRoutineEvent.daysOfWeek)
        }
        .discreetListItem()
        .listSectionMargins(.vertical, 0)
    }

    @ViewBuilder
    private var timeField: some View {
        Group {
            if let timeAndDay {
                HStack {
                    Image(systemName: "clock")
                    Text("")
                    Spacer()
                    TimeView(timeInRegion: timeAndDay)
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: togglePicker)
            } else {
                FormLabelView(
                    systemImageName: "clock",
                    value: "Add Time"
                ) {
                    ensureTextfieldBlurred()
                    draftRoutineEvent.hasTime = true
                    togglePicker()
                }
            }
        }
        .listRowSeparator(showTimePicker ? .hidden : .visible)
    }

    @ViewBuilder
    private var timePicker: some View {
        if showTimePicker {
            VStack {
                DatePicker(
                    "",
                    selection: $draftRoutineEvent.date,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.wheel)

                ActionButtonView(
                    label: "Remove Time",
                    systemImage: "xmark"
                ) {
                    draftRoutineEvent.hasTime = false
                    togglePicker()
                }
            }
            .alignmentGuide(.listRowSeparatorLeading) { _ in 32 }
            .listRowInsets(.top, 0)
        }
    }

    // MARK: - Functions

    private func saveRoutineEvent() {
        let affectedWeekdays = (sourceRoutineEvent?.weekdays ?? []).union(
            draftRoutineEvent.daysOfWeek
        )

        PlannerSyncStore.invalidateRoutineDays(affectedWeekdays)

        modelContext.updateRoutineEvent(
            with: draftRoutineEvent,
            sourceRoutineEvent: sourceRoutineEvent,
            sortedSourceEvents: sortedSourceEvents
        )

        dismiss()

        if sourceDayOfWeek == nil
            || !draftRoutineEvent.daysOfWeek.contains(sourceDayOfWeek!)
        {
            let selectedDays = draftRoutineEvent.daysOfWeek
            
            let subtitle: String? = {
                if selectedDays.count > 1 {
                    return nil
                }

                if let destinationDay = selectedDays.first?.rawValue
                    .capitalized
                {
                    return "\(destinationDay)s"
                }

                return ""
            }()
            
            let customSubtitle: AnyView? = {
                if selectedDays.count == 1 {
                    return nil
                }
                return AnyView(WeekdaySpreadView(
                    selected: selectedDays,
                    scale: 0.66,
                    spacing: 1,
                    customAccentColor: Color.label
                ))
            }()

            let canOpenDestinationRoutine = {
                guard selectedDays.count == 1 else { return false }

                return selectedDays.first! != sourceDayOfWeek
            }()

            let onClick =
                canOpenDestinationRoutine
                ? {
                    openRoutine(selectedDays.first!)
                } : nil

            if sourceRoutineEvent != nil {
                showToast(
                    Toast(
                        title: "Successfully moved recurring event!",
                        subtitle: subtitle,
                        customSubtitle: customSubtitle,
                        iconConfig: IconConfig(
                            name: "arrow.left.arrow.right",
                            primaryColor: Color.label,
                            secondaryColor: Color.label
                        ),
                        action: onClick
                    )
                )
            } else {
                showToast(
                    Toast(
                        title: "Successfully created recurring event!",
                        subtitle: subtitle,
                        customSubtitle: customSubtitle,
                        iconConfig: IconConfig(
                            name: "repeat",
                            primaryColor: Color.label
                        ),
                        variant: .tab,
                        action: onClick
                    )
                )
            }
        }
    }

    private func deleteEvent() {
        dismiss()

        if let sourceRoutineEvent {
            modelContext.safeDelete(sourceRoutineEvent)
        }
    }

    private func ensureTextfieldBlurred() {
        if isTitleFocused {
            isTitleFocused = false
        }
    }

    private func togglePicker() {
        ensureTextfieldBlurred()
        showTimePicker.toggle()
    }

}
