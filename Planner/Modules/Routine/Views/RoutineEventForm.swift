//
//  RoutineEventForm.swift
//  Planner
//
//  Created by Alex Green on 4/6/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct RoutineEventFormView: View {
    private let sourceRoutineEvent: RoutineEventContext?
    private let sourceWeekday: Weekday?
    private let sourceSortedRoutineEvents: [RoutineEventContext]?
    private let openRoutine: (Weekday) -> Void

    // MARK: Create Routine Event (Dashboard)
    init(openRoutine: @escaping (Weekday) -> Void) {
        self.sourceRoutineEvent = nil
        self.sourceWeekday = nil
        self.sourceSortedRoutineEvents = nil
        self.openRoutine = openRoutine

        self._draftRoutineEvent = State(
            initialValue: DraftRoutineEvent()
        )
    }

    // MARK: Edit Routine Event (Routine)
    init(
        sourceRoutineEvent: RoutineEventContext,
        sourceWeekday: Weekday,
        sourceSortedRoutineEvents: [RoutineEventContext],
        openRoutine: @escaping (Weekday) -> Void
    ) {
        self.sourceRoutineEvent = sourceRoutineEvent
        self.sourceWeekday = sourceWeekday
        self.sourceSortedRoutineEvents = sourceSortedRoutineEvents
        self.openRoutine = openRoutine

        _draftRoutineEvent = State(
            initialValue: DraftRoutineEvent(routineEvent: sourceRoutineEvent)
        )
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.showToast) private var showToast
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var calendarService: CalendarService

    @State private var draftRoutineEvent: DraftRoutineEvent

    @State private var showDeleteConfirmation = false
    @State private var showTimePicker = false
    @State private var hasTitleAutoFocused = false

    @FocusState private var isTitleFocused

    private var isCreateForm: Bool {
        sourceRoutineEvent == nil
    }

    private var canSave: Bool {
        !draftRoutineEvent.title.trimmed.isEmpty
            && !draftRoutineEvent.weekdays.isEmpty
    }

    private var dateInUtc: DateInRegion? {
        guard draftRoutineEvent.hasTime else {
            return nil
        }

        return DateInRegion(draftRoutineEvent.date, region: .UTC)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                FormTitleFieldView(
                    text: $draftRoutineEvent.title,
                    hasAutoFocused: $hasTitleAutoFocused,
                    isFocused: $isTitleFocused
                )

                daysSection
                detailsSection
            }
            .toolbar {
                cancelButton

                FormSaveButtonView(canSave: canSave, save: saveRoutineEvent)

                deleteButton
            }
            .navigationTitle(
                isCreateForm ? "Create Recurring Event" : "Edit Recurring Event"
            )
            .navigationBarTitleDisplayMode(.inline)
        }

        // MARK: Blur the title field whenever the weekdays change.
        .onChange(of: draftRoutineEvent.weekdays) { _, _ in
            isTitleFocused = false
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            CancelButtonView(cancel: {
                isTitleFocused = false
                dismiss()
            })
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
                        routineEventContext: sourceRoutineEvent!,
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

    private var detailsSection: some View {
        Section {
            timeField
            timePicker
        }
        .listSectionSeparator(.hidden)
    }

    private var daysSection: some View {
        Section {
            WeekdayPickerView(selectedWeekdays: $draftRoutineEvent.weekdays)
        }
        .listSectionMargins(.vertical, 0)
        .discreetListItem()
    }

    private var timeField: some View {
        Group {
            if let dateInUtc {
                FormLabelView(
                    systemImageName: "clock",
                    value: Time(timeInRegion: dateInUtc),
                    onTap: togglePicker
                )
            } else {
                FormLabelView(
                    systemImageName: "clock",
                    value: "Add Time"
                ) {
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
                .datePickerStyle(.wheel)
                .environment(\.timeZone, .gmt)

                ActionButtonView(
                    label: "Remove Time",
                    systemImage: "xmark"
                ) {
                    draftRoutineEvent.hasTime = false
                    togglePicker()
                }
            }
            .listRowInsets(.top, 0)
        }
    }

    // MARK: - Functions

    private func saveRoutineEvent() {
        modelContext.updateRoutineEventContext(
            sourceRoutineEvent,
            with: draftRoutineEvent,
            sourceSortedRoutineEventContexts: sourceSortedRoutineEvents,
            plannerService: plannerService,
            ekEventStore: calendarService.ekEventStore
        )

        dismiss()

        showNotification()
    }
    
    private func deleteEvent() {
        dismiss()

        if let sourceRoutineEvent {
            modelContext.safeDelete(sourceRoutineEvent)
        }
    }

    private func showNotification() {
        guard
            isCreateForm
                || !draftRoutineEvent.weekdays.contains(sourceWeekday!)
        else {
            return
        }

        let selectedWeekdays = draftRoutineEvent.weekdays

        let subtitle: LocalizedStringKey? = {
            guard selectedWeekdays.count == 1,
                let weekday = selectedWeekdays.first
            else { return nil }

            return LocalizedStringKey(weekday.label)
        }()

        let customSubtitle: AnyView? = {
            if selectedWeekdays.count < 2 {
                return nil
            }

            return AnyView(
                WeekdaySpreadView(
                    selected: selectedWeekdays,
                    accentColor: Color.label
                )
            )
        }()

        let canOpenDestinationRoutine = {
            guard selectedWeekdays.count == 1,
                let weekday = selectedWeekdays.first
            else { return false }

            return weekday != sourceWeekday
        }()

        let onClick =
            canOpenDestinationRoutine
            ? {
                openRoutine(selectedWeekdays.first!)
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

    private func togglePicker() {
        isTitleFocused = false

        withAnimation {
            showTimePicker.toggle()
        }
    }
}
