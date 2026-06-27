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
    let sourcePlannerEvent: PlannerEvent?
    let sourcePlanner: Planner?
    let settings: PlannerSettings
    let showNotification: (Set<String>) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerSyncService: PlannerSyncService
    @EnvironmentObject private var locationService: LocationService

    @State private var visiblePicker: VisibleEventFormPicker = .none
    @State private var hasTitleAutoFocused = false
    @State private var showDeleteConfirmation = false

    @FocusState private var isTitleFocused

    private var isCreateForm: Bool {
        sourcePlannerEvent == nil
    }

    private var canSave: Bool {
        !draftPlannerEvent.title.trimmed.isEmpty
    }

    private var sourceEkEvent: EKEvent? {
        sourcePlannerEvent?.eKEventContext?.ekEvent
    }

    private var dateInRegion: DateInRegion {
        DateInRegion(draftPlannerEvent.date, region: region)
    }

    private var region: Region {
        draftPlannerEvent
            .region(
                planner: sourcePlanner,
                settings: settings,
                deviceLocation: locationService.deviceLocation
            )
    }

    private var defaultLocation: Location? {
        sourcePlanner?.location(
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )
            ?? settings.homeLocation(
                deviceLocation: locationService.deviceLocation
            )
    }

    // MARK: - Body

    var body: some View {
        Form {
            FormTitleFieldView(
                text: $draftPlannerEvent.title,
                hasAutoFocused: $hasTitleAutoFocused,
                isFocused: $isTitleFocused
            )

            detailsSection
        }
        .toolbar {
            cancelButton

            FormSaveButtonView(canSave: canSave, save: savePlannerEvent)

            deleteButton

            ToolbarSpacer(placement: .bottomBar)

            addToCalendarButton
        }
        .navigationTitle(isCreateForm ? "Create Event" : "Edit Event")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            CancelButtonView {
                isTitleFocused = false

                if let sourcePlannerEvent,
                    sourcePlannerEvent.title.trimmed.isEmpty
                {
                    // The title was empty when this sheet was opened. Delete the event.
                    modelContext.deletePlannerEvent(
                        sourcePlannerEvent,
                        ekEventStore: calendarService.ekEventStore
                    )
                }

                dismiss()
            }
        }
    }

    @ToolbarContentBuilder
    private var deleteButton: some ToolbarContent {
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
                        delete: deleteSourceEvent
                    ),
                    isPresented: $showDeleteConfirmation
                )
            }
        }
    }

    @ToolbarContentBuilder
    private var addToCalendarButton: some ToolbarContent {
        if calendarService.hasAccess == true {
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
                sourcePlanner: sourcePlanner,
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
                        ? Color.secondary : accentColor.color,
                    secondaryColor: Color.label
                ),
                label: draftPlannerEvent.location?.name
                    ?? (sourcePlanner != nil
                        ? "Planner Location" : "Home Location")
            )
        }
    }

    // MARK: - Functions

    private func savePlannerEvent() {
        let destinationDatestamps = modelContext.updatePlannerEvent(
            sourcePlannerEvent,
            with: draftPlannerEvent,
            destinationDatestamp: DateInRegion(
                draftPlannerEvent.date,
                region: region
            ).datestamp,
            sourcePlanner: sourcePlanner,
            timeZone: region.timeZone,
            plannerSyncService: plannerSyncService,
            ekEventStore: calendarService.ekEventStore,
            settings: settings
        )

        dismiss()

        showNotification(destinationDatestamps)
    }

    private func deleteSourceEvent() {
        dismiss()

        guard let sourcePlannerEvent else { return }

        modelContext.deletePlannerEvent(
            sourcePlannerEvent,
            ekEventStore: calendarService.ekEventStore
        )
    }

    private func addEventToCalendar() {
        let ekEvent =
            sourceEkEvent
            ?? EKEvent(
                eventStore: calendarService.ekEventStore
            )

        ekEvent.calendar =
            sourceEkEvent?.calendar
            ?? calendarService.ekEventStore
            .defaultCalendarForNewEvents

        // Migrate event location into the calendar event.
        if let location = draftPlannerEvent.location {
            ekEvent.location = location.name

            ekEvent.structuredLocation = EKStructuredLocation(
                title: location.name,
            )

            ekEvent.structuredLocation?.geoLocation = CLLocation(
                latitude: location.latitude,
                longitude: location.longitude
            )

        }

        ekEvent.title = draftPlannerEvent.title
        ekEvent.startDate = draftPlannerEvent.date
        ekEvent.endDate = Calendar.current.date(
            byAdding: .hour,
            value: 1,
            to: draftPlannerEvent.date
        )
        ekEvent.timeZone = region.timeZone

        draftPlannerEvent.ekEvent = ekEvent
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
