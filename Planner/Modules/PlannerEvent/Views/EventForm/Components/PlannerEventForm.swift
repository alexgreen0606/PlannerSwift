//
//  PlannerEventForm.swift
//  Planner
//
//  Created by Alex Green on 3/9/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

struct PlannerEventFormView: View {
    @Binding var draftPlannerEvent: DraftPlannerEvent
    let settings: PlannerSettings
    let defaultLocation: Location?
    let sourceCalendarEvent: EKEvent?
    let sourcePlannerEvent: PlannerEvent?
    let sourcePlanner: Planner?
    let showNotification: (String?, Set<String>, EKEvent?) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var PlannerCoverStore: PlannerCoverStore
    @EnvironmentObject private var PlannerSyncStore: PlannerSyncService
    @EnvironmentObject private var LocationService: LocationService

    @State private var showDeleteConfirmation = false
    @State private var visiblePicker: VisibleEventFormPicker = .none
    @State private var hasTitleAutoFocused = false

    @FocusState private var isTitleFocused

    private var isCreateForm: Bool {
        sourcePlannerEvent == nil && sourceCalendarEvent == nil
    }

    private var canSave: Bool {
        !draftPlannerEvent.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
    }

    private var eventRegion: Region {
        draftPlannerEvent
            .region(
                planner: sourcePlanner,
                settings: settings,
                deviceLocation: LocationService.deviceLocation
            )
    }

    private var timeAndDay: DateInRegion {
        DateInRegion(draftPlannerEvent.date, region: eventRegion)
    }

    private var timeZoneAbbreviation: String {
        eventRegion.timeZone.abbreviation() ?? "Unknown Time Zone"
    }

    private var showCalendarButton: Bool {
        calendarStore.hasAccess == true
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                titleSection
                detailsSection
            }
            .animation(.linear, value: visiblePicker)
            .toolbar {
                cancelButton
                FormSaveButtonView(canSave: canSave, save: savePlannerEvent)
                bottomToolbar
            }
            .navigationTitle(isCreateForm ? "Create Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
        }
        .transition(.opacity)
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            CancelButtonView {
                isTitleFocused = false

                if let sourcePlannerEvent, let sourcePlanner,
                    sourcePlannerEvent.title.trimmed.isEmpty
                {
                    // The title was empty when this sheet was open. Delete the event.
                    modelContext.deletePlannerEvent(
                        sourcePlannerEvent,
                        in: sourcePlanner,
                        ekEventStore: calendarStore.ekEventStore
                    )
                }

                dismiss()
            }
        }
    }

    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        if let sourcePlannerEvent {
            ToolbarItem(placement: .bottomBar) {
                Button("", systemImage: "trash") {
                    showDeleteConfirmation = true
                }
                .tint(Color.red)
                .withConfirmation(
                    deletePlannerEventConfig(
                        event: sourcePlannerEvent,
                        inForm: true,
                        delete: deleteEvent
                    ),
                    isPresented: $showDeleteConfirmation
                )
            }

            ToolbarSpacer(placement: .bottomBar)

            ToolbarItem(placement: .bottomBar) {
                Button("Add to Calendar") {
                    addEventToCalendar()
                }
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .tint(accentColor.color)
            }
        }
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

    private var dateField: some View {
        FormLabelView(
            systemImageName: "calendar",
            value: timeAndDay.datestamp.dateLabel(
                todaystamp: todayService.todaystamp
            )
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
            .listRowInsets(.top, 0)
        }
    }

    private var timeField: some View {
        Group {
            if draftPlannerEvent.hasTime {
                HStack {
                    Image(systemName: "clock")
                    Text("")
                    Spacer()
                    VStack(alignment: .trailing) {
                        Time(timeInRegion: timeAndDay)
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
                    value: "Add Time"
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
                    in: todayService.datePickerBounds,
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
            LocationFormView(
                variant: .event,
                initialLocation: draftPlannerEvent.location,
                sourcePlanner: sourcePlanner,
                settings: settings,
                saveSelection: { location in
                    draftPlannerEvent.location = location
                }
            )
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
                        ?? (sourcePlanner != nil
                            ? "Planner Location" : "Home Location")
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Functions

    private func savePlannerEvent() {
        let destinationDatestamp = modelContext.updatePlannerEvent(
            sourcePlannerEvent,
            with: draftPlannerEvent,
            destinationDatestamp: DateInRegion(
                draftPlannerEvent.date,
                region: eventRegion
            ).datestamp,
            sourceCalendarEvent: sourceCalendarEvent,
            sourcePlanner: sourcePlanner,
            timeZone: eventRegion.timeZone,
            ekEventStore: calendarStore.ekEventStore,
            settings: settings
        )

        // Refresh calendar in case of recurring/all-day events.
        DispatchQueue.main.async(
            execute: PlannerSyncStore.syncCalendar
        )

        dismiss()

        let destinationDatestamps: Set<String> = {
            guard let sourcePlanner else {
                return []
            }

            return [sourcePlanner.datestamp]
        }()

        showNotification(sourcePlanner?.datestamp, destinationDatestamps, nil)
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
            modelContext.safeDelete(sourcePlannerEvent)
        }
    }

    private func ensureTextfieldBlurred() {
        if isTitleFocused {
            isTitleFocused = false
        }
    }

    private func togglePicker(type: VisibleEventFormPicker) {
        ensureTextfieldBlurred()

        if visiblePicker == type {
            visiblePicker = .none
        } else {
            visiblePicker = type
        }
    }
}
