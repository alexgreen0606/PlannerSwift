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
    var daysOfWeek: Set<DayOfWeek>
}

struct RoutineEventFormView: View {
    let sourceRoutineEvent: RoutineEvent?
    let sourceDayOfWeek: DayOfWeek?

    init(
        sourceRoutineEvent: RoutineEvent? = nil,
        sourceDayOfWeek: DayOfWeek? = nil
    ) {
        self.sourceRoutineEvent = sourceRoutineEvent
        self.sourceDayOfWeek = sourceDayOfWeek

        let daysOfWeek: Set<DayOfWeek> = sourceRoutineEvent?.daysOfWeek ?? []

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

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationManager: NotificationManager

    @State private var draftRoutineEvent: DraftRoutineEvent

    @State private var showDeleteConfirmation = false
    @State private var showTimePicker = false
    @State private var hasTitleAutoFocused = false

    @FocusState private var isTitleFocused

    private var isCreateForm: Bool {
        sourceRoutineEvent == nil
    }

    private var canSave: Bool {
        !draftRoutineEvent.title.isEmpty
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
                .confirmationDialog(
                    "Delete recurring event?",
                    isPresented: $showDeleteConfirmation,
                    titleVisibility: .visible
                ) {
                    Button(
                        "Confirm",
                        role: .destructive,
                        action: deleteEvent
                    )
                } message: {
                    Text(
                        "This will delete all occurrences of the event from your routines and planner. This action cannot be undone."
                    )
                }
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
        modelContext.updateRoutineEvent(
            with: draftRoutineEvent,
            sourceRoutineEvent: sourceRoutineEvent
        )

        dismiss()

        if sourceDayOfWeek == nil
            || !draftRoutineEvent.daysOfWeek.contains(sourceDayOfWeek!)
        {
            DispatchQueue.main.async {

                let destinations = {
                    let selectedDays = draftRoutineEvent.daysOfWeek

                    if selectedDays.count > 1 {
                        return DayOfWeek.allCases
                            .filter { selectedDays.contains($0) }
                            .map { $0.initial }
                            .joined()
                    }

                    if let destinationDay = selectedDays.first?.rawValue
                        .capitalizedFirst
                    {
                        return "\(destinationDay)s"
                    }

                    return ""
                }()

                notificationManager.addNotification(
                    NotificationConfig(
                        id: UUID(),
                        title: "Recurring event moved",
                        subtitle: "to \(destinations)",
                        iconConfig: IconConfig(
                            name: "checkmark",
                            primaryColor: Color.green
                        ),
                        onClick: {
                            // TODO: only use onClick if One destination exists.

                        }
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
