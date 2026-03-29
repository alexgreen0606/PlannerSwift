//
//  PlannerEventForm.swift
//  Planner
//
//  Created by Alex Green on 3/9/26.
//

import EventKit
import SwiftDate
import SwiftUI
import SwiftUIIntrospect

// Clean

enum VisiblePicker {
    case date
    case time
    case none
}

struct PlannerEventFormView: View {
    @Binding var draftPlannerEvent: DraftPlannerEvent
    let settings: PlannerSettings
    let defaultLocation: Location?
    let sourceCalendarEvent: EKEvent?
    let sourcePlannerEvent: PlannerEvent?
    let sourcePlanner: Planner?
    let sourceDay: DateInRegion?
    let showNotification: (DateInRegion?, DateInRegion?, EKEvent?) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            KeepPastEventsDuration.oneMonth

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var plannerCoverManager: PlannerCoverManager
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @State private var showDeleteConfirmation = false
    @State private var visiblePicker: VisiblePicker = .none
    @State private var hasTitleAutoFocused = false

    @FocusState private var isTitleFocused

    private var eventRegion: Region {
        draftPlannerEvent
            .region(
                planner: sourcePlanner,
                settings: settings,
                deviceLocation: deviceLocationManager.deviceLocation
            )
    }

    private var timeAndDay: DateInRegion {
        DateInRegion(draftPlannerEvent.date, region: eventRegion)
    }

    private var timeZoneAbbreviation: String {
        eventRegion.timeZone.abbreviation() ?? "Unknown Time Zone"
    }

    private var isCreateForm: Bool {
        sourcePlannerEvent == nil && sourceCalendarEvent == nil
    }

    private var canSave: Bool {
        !draftPlannerEvent.title.isEmpty
    }

    private var showCalendarButton: Bool {
        calendarStore.calendarAccessDenied == false
    }

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                detailsSection
            }
            .animation(.linear, value: visiblePicker)
            .navigationTitle(isCreateForm ? "Create Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelButton
                saveButton
                bottomToolbar
            }
        }
        .transition(.opacity)
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
            Button("Save", systemImage: "checkmark", action: savePlannerEvent)
                .buttonStyle(.glassProminent)
                .tint(canSave ? accentColor.color : .tertiary)
                .disabled(!canSave)
        }
    }

    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            HStack {
                deleteButton
                addToCalendarButton
            }
        }
        .sharedBackgroundVisibility(.hidden)
    }

    // MARK: - View Builders

    private var titleSection: some View {
        FormTitleFieldView(
            text: $draftPlannerEvent.title,
            hasAutoFocused: $hasTitleAutoFocused,
            isFocused: $isTitleFocused
        )
    }

    private var detailsSection: some View {
        Section {
            dateField
            datePicker
            timeField
            timePicker
            locationField
        }
        .listSectionSeparator(.hidden)
        .environment(\.timeZone, eventRegion.timeZone)
    }

    @ViewBuilder
    private var dateField: some View {
        FormLabelView(systemImageName: "calendar", value: timeAndDay.dateLabel)
        {
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
                in: keepPastEventsDuration
                    .cutoffDate...todaystampWatcher
                    .maxCalendarDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .listRowInsets(.top, 0)
        }
    }

    @ViewBuilder
    private var timeField: some View {
        Group {
            if draftPlannerEvent.hasTime {
                HStack {
                    Image(systemName: "clock")
                    Text("")
                    Spacer()
                    VStack(alignment: .trailing) {
                        TimeView(timeInRegion: timeAndDay)
                        Text(timeZoneAbbreviation)
                            .font(
                                .system(
                                    size: 11,
                                    weight: .bold,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(Color.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    togglePicker(type: .time)
                }
            } else {
                FormLabelView(
                    systemImageName: "clock",
                    value: draftPlannerEvent.hasTime
                        ? timeAndDay.dateLabel : "Add Time"
                ) {
                    ensureTextfieldBlurred()
                    draftPlannerEvent.hasTime = true
                    visiblePicker = .time
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
                    in: keepPastEventsDuration
                        .cutoffDate...todaystampWatcher
                        .maxCalendarDate,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.wheel)

                ActionButtonView(
                    label: "Remove Time",
                    systemImage: "xmark"
                ) {
                    draftPlannerEvent.hasTime = false
                    visiblePicker = .none
                }
            }
            .alignmentGuide(.listRowSeparatorLeading) { _ in 32 }
            .listRowInsets(.top, 0)
        }
    }

    private var locationField: some View {
        NavigationLink {
            LocationSearchFormView(
                title: "Edit Event Location",
                mode: .event,
                settings: settings,
                initialLocation: draftPlannerEvent.location,
                sourcePlanner: sourcePlanner
            ) { location in
                draftPlannerEvent.location = location
            }
        } label: {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .imageScale(.medium)
                    .foregroundStyle(
                        draftPlannerEvent.location == nil
                            ? Color.secondary : accentColor.color,
                        Color.label
                    )
                Text("")
                Spacer()
                Text(
                    draftPlannerEvent.location?.name
                    ?? (sourcePlanner != nil ? "Planner Location" : "Home Location")
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var addToCalendarButton: some View {
        if showCalendarButton {
            ActionButtonView(
                label: "Add To Calendar",
                systemImage: "calendar.badge.plus",
                onTap: addEventToCalendar
            )
        }
    }

    @ViewBuilder
    private var deleteButton: some View {
        if !isCreateForm {
            ActionButtonView(
                label: "Delete Event",
                systemImage: "trash",
                color: Color.red,
                onTap: {
                    showDeleteConfirmation = true
                }
            )
            .confirmationDialog(
                "Delete this event?",
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
                    "This action is irreversible."
                )
            }

            if showCalendarButton {
                Spacer()
            }
        }
    }

    // MARK: - Functions

    private func savePlannerEvent() {

        let destinationDay = modelContext.handlePlannerEventChange(
            draftPlannerEvent,
            sourceDay: sourceDay,
            targetDatestamp: DateInRegion(
                draftPlannerEvent.date,
                region: eventRegion
            ).datestamp,
            settings: settings,
            ekEventStore: calendarStore.ekEventStore,
            sourcePlannerEvent: sourcePlannerEvent,
            sourceCalendarEvent: sourceCalendarEvent
        )

        // Refresh calendar in case of recurring events.
        DispatchQueue.main.async {
            calendarStore.attemptFreshLoad(
                hiddenCalendarIds: settings.hiddenCalendarIds
            )
        }

        dismiss()

        showNotification(sourceDay, destinationDay, nil)
    }

    private func addEventToCalendar() {

        // Build a calendar event to represent the form values.
        let event =
            sourceCalendarEvent
            ?? EKEvent(
                eventStore: calendarStore.ekEventStore
            )
        event.calendar =
            sourceCalendarEvent?.calendar
            ?? calendarStore.ekEventStore
            .defaultCalendarForNewEvents

        if let location = draftPlannerEvent.location ?? defaultLocation {

            // Location display name.
            event.location = location.name

            // Location coordinates.
            let structuredLocation = EKStructuredLocation(
                title: location.name
            )
            structuredLocation.geoLocation = CLLocation(
                latitude: location.latitude,
                longitude: location.longitude
            )
            event.structuredLocation = structuredLocation

            // Location time zone.
            event.timeZone = TimeZone(
                identifier: location.timeZoneIdentifier
            )

        }

        event.title = draftPlannerEvent.title
        event.startDate = draftPlannerEvent.date
        event.endDate = Calendar.current.date(
            byAdding: .hour,
            value: 1,
            to: draftPlannerEvent.date
        )

        withAnimation {
            visiblePicker = .none
            draftPlannerEvent.calendarEvent = event
        }
    }

    private func deleteEvent() {
        dismiss()

        if let sourcePlannerEvent {
            modelContext.deletePlannerEvents([sourcePlannerEvent])
        }
    }

    private func ensureTextfieldBlurred() {
        if isTitleFocused {
            isTitleFocused = false
        }
    }

    private func togglePicker(type: VisiblePicker) {
        ensureTextfieldBlurred()

        if visiblePicker == type {
            visiblePicker = .none
        } else {
            visiblePicker = type
        }
    }

}
