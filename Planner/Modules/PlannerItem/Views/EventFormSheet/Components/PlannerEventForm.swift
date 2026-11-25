//
//  PlannerEventForm.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

/// The planner event half of the event form.
/// When the original item is a calendar event, saving converts it into a Planner-owned event.
struct PlannerEventFormView: View {
    private let item: PlannerItem
    private let planner: Planner
    private let settings: Settings
    /// Hands the current draft and its calendar event to the calendar form.
    private let addToCalendar: (DraftPlannerEvent, EKEvent) -> Void

    init(
        item: PlannerItem,
        initialDraft: DraftPlannerEvent,
        planner: Planner,
        settings: Settings,
        addToCalendar: @escaping (DraftPlannerEvent, EKEvent) -> Void
    ) {
        self.item = item
        self.planner = planner
        self.settings = settings
        self.addToCalendar = addToCalendar

        self._draftPlannerEvent = State(initialValue: initialDraft)
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.showToast) private var showToast
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    @State private var draftPlannerEvent: DraftPlannerEvent
    @State private var visiblePicker: VisibleEventFormPicker = .none
    @State private var hasTitleAutoFocused = false
    @State private var showDeleteConfirmation = false

    @FocusState private var isTitleFocused
    @FocusState private var isNotesFocused

    private var canSave: Bool {
        !draftPlannerEvent.title.trimmed.isEmpty
    }

    private var dateInRegion: DateInRegion {
        DateInRegion(draftPlannerEvent.date, region: region)
    }

    private var region: Region {
        draftPlannerEvent
            .region(
                planner: planner,
                settings: settings
            )
    }

    private var defaultLocation: Location? {
        planner.location(
            settings: settings
        )
            ?? settings.homeLocation
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                FormTitleFieldView(
                    text: $draftPlannerEvent.title,
                    hasAutoFocused: $hasTitleAutoFocused,
                    isFocused: $isTitleFocused
                )

                detailsSection

                FormNotesFieldView(
                    notes: $draftPlannerEvent.notes,
                    isFocused: $isNotesFocused
                )

                flagSection
            }
            .toolbar {
                cancelButton

                FormSaveButtonView(canSave: canSave, save: savePlannerEvent)

                deleteButton

                ToolbarSpacer(placement: .bottomBar)

                addToCalendarButton
            }
            .safeAreaBar(edge: .bottom) {
                keyboardAdornment
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            CancelButtonView {
                isTitleFocused = false

                // The source event had an empty title. Delete it.
                if item.title.trimmed.isEmpty {
                    switch item.source {
                    case .plannerEvent(let plannerEvent):
                        modelContext.deletePlannerEvent(plannerEvent)

                    case .ekEvent(let ekEvent, let state):
                        _ = calendarService.ekEventStore.attemptDeleteEvent(
                            ekEvent
                        )

                        modelContext.deleteEkEventPlannerState(
                            for: ekEvent,
                            existing: state
                        )
                    }

                    modelContext.safeSave(
                        "PlannerEventForm cancelButton"
                    )
                }

                dismiss()
            }
        }
    }

    @ToolbarContentBuilder
    private var deleteButton: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button("", systemImage: "trash") {
                showDeleteConfirmation = true
            }
            .tint(Color.red)
            .withConfirmation(
                deletePlannerItemConfig(
                    item: item,
                    inForm: true,
                    delete: deleteSourceItem
                ),
                isPresented: $showDeleteConfirmation
            )
        }
    }

    @ToolbarContentBuilder
    private var addToCalendarButton: some ToolbarContent {
        if calendarService.hasCalendarAccess == true {
            ToolbarItem(placement: .bottomBar) {
                Button(
                    "Add to Calendar",
                    action: addEventToCalendar
                )
                .fontWeight(.medium)
            }
        }
    }

    // MARK: - View Builders

    private var detailsSection: some View {
        Section {
            dateField
            datePicker
            timeField
            timePicker
            locationField
        }
        .listSectionSeparator(.hidden)
        .environment(\.timeZone, region.timeZone)
    }

    private var dateField: some View {
        FormLabelView(
            systemImageName: "calendar",
            value: dateInRegion.datestamp.dateLabel(
                todaystamp: todayService.todaystamp
            ),
            detail: LocalizedStringKey(dateInRegion.datestamp.weekday)
        ) {
            togglePicker(type: .date)
        }
        .listRowSeparator(visiblePicker == .date ? .hidden : .visible)
    }

    @ViewBuilder
    private var datePicker: some View {
        if visiblePicker == .date {
            DatePicker(
                "",
                selection: $draftPlannerEvent.date,
                in: todayService.datePickerBounds,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .tint(accentColor.swiftUiColor)
            .listRowInsets(.top, 0)
        }
    }

    private var timeField: some View {
        Group {
            if draftPlannerEvent.hasTime {
                FormLabelView(
                    systemImageName: "clock",
                    value: Time(timeInRegion: dateInRegion),
                    detail: LocalizedStringKey(
                        region.timeZone.abbreviation() ?? "Unknown Time Zone"
                    )
                ) {
                    togglePicker(type: .time)
                }
            } else {
                FormLabelView(
                    systemImageName: "clock",
                    value: "Add Time"
                ) {
                    isTitleFocused = false

                    withAnimation {
                        visiblePicker = .time
                        draftPlannerEvent.hasTime = true

                        // Set a location for the event so absolute point in time is clear to user.
                        if draftPlannerEvent.hasTime,
                            draftPlannerEvent.location == nil
                        {
                            draftPlannerEvent.location = defaultLocation
                        }
                    }
                }
            }
        }
        .listRowSeparator(visiblePicker == .time ? .hidden : .visible)
    }

    @ViewBuilder
    private var timePicker: some View {
        if visiblePicker == .time {
            VStack {
                DatePicker(
                    "",
                    selection: $draftPlannerEvent.date,
                    in: todayService.datePickerBounds,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()

                ActionButtonView(
                    label: "Remove Time",
                    systemImage: "xmark"
                ) {
                    isTitleFocused = false

                    withAnimation {
                        draftPlannerEvent.hasTime = false
                        visiblePicker = .none
                    }
                }
            }
            .alignmentGuide(.listRowSeparatorLeading) { _ in 32 }
            .listRowInsets(.top, 0)
        }
    }

    private var locationField: some View {
        NavigationLink {
            LocationFormView(
                variant: .event,
                initialLocation: draftPlannerEvent.location,
                sourcePlanner: planner,
                settings: settings,
                saveSelection: { location in
                    draftPlannerEvent.location = location
                }
            )
        } label: {
            FormNavigationLinkView(
                iconConfig: IconConfig(
                    name: "mappin.and.ellipse",
                    primaryColor: draftPlannerEvent.location == nil
                        ? Color.secondary : accentColor.swiftUiColor,
                    secondaryColor: Color.label
                ),
                label: draftPlannerEvent.location?.name ?? "Planner Location"
            )
        }
    }

    private var flagSection: some View {
        Section {
            Toggle(isOn: $draftPlannerEvent.isFlagged) {
                Image(
                    systemName: draftPlannerEvent.isFlagged
                        ? "flag.fill" : "flag"
                )
                .foregroundStyle(
                    draftPlannerEvent.isFlagged
                        ? accentColor.swiftUiColor : Color.label
                )
            }
            .tint(accentColor.swiftUiColor)
        } footer: {
            if draftPlannerEvent.isFlagged {
                Text(
                    "Flagged events will carry forward to the present day until completed."
                )
            }
        }
    }

    @ViewBuilder
    private var keyboardAdornment: some View {
        if isNotesFocused {
            HStack {
                Spacer()

                GlassIconButtonView(
                    systemImageName: "checkmark",
                    onTap: {
                        isNotesFocused = false
                    }
                )
            }
            .padding(8)
        }
    }

    // MARK: - Functions

    private func savePlannerEvent() {
        let sourcePlannerEvent: PlannerEvent?

        switch item.source {
        case .plannerEvent(let plannerEvent):
            sourcePlannerEvent = plannerEvent

        case .ekEvent(let ekEvent, let state):
            ekEvent.rollback()

            // The event is being removed from the calendar. Only continue if the deletion succeeds,
            // otherwise the event would be duplicated.
            guard calendarService.ekEventStore.attemptDeleteEvent(ekEvent)
            else { return }

            modelContext.deleteEkEventPlannerState(
                for: ekEvent,
                existing: state
            )

            sourcePlannerEvent = nil
        }

        let destinationDatestamps = modelContext.updatePlannerEvent(
            sourcePlannerEvent,
            with: draftPlannerEvent,
            destinationDatestamp: dateInRegion.datestamp,
            sourcePlanner: planner,
            timeZone: region.timeZone,
            todayService: todayService,
            plannerService: plannerService,
            todaystamp: todayService.todaystamp,
            ekEventStore: calendarService.ekEventStore,
            settings: settings
        )

        dismiss()

        showEventFormNotification(
            destinationDatestamps: destinationDatestamps,
            sourceDatestamp: planner.datestamp,
            todayService: todayService,
            plannerCoverStore: plannerCoverStore,
            showToast: showToast
        )
    }

    private func deleteSourceItem() {
        dismiss()

        modelContext.deletePlannerItem(
            item,
            ekEventStore: calendarService.ekEventStore
        )
    }

    private func addEventToCalendar() {
        isTitleFocused = false
        isNotesFocused = false

        let ekEvent = draftPlannerEvent.makeEkEvent(
            sourceEkEvent: item.ekEvent,
            ekEventStore: calendarService.ekEventStore,
            timeZone: region.timeZone
        )

        addToCalendar(draftPlannerEvent, ekEvent)
    }

    private func togglePicker(type: VisibleEventFormPicker) {
        isTitleFocused = false

        withAnimation {
            if visiblePicker == type {
                visiblePicker = .none
            } else {
                visiblePicker = type
            }
        }
    }
}
