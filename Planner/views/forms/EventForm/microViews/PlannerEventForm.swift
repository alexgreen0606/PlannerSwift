//
//  PlannerEventForm.swift
//  Planner
//
//  Created by Alex Green on 3/9/26.
//

import EventKit
import SwiftDate
import SwiftUI

// Clean

struct PlannerEventFormView: View {
    @Binding var draftPlannerEvent: DraftPlannerEvent
    @Binding var sheetDetent: PresentationDetent
    let settings: PlannerSettings
    let defaultLocation: Location?
    let initialCalendarEvent: EKEvent?
    let initialPlannerEvent: PlannerEvent?
    let sourcePlanner: Planner?

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    private var eventRegion: Region {
        draftPlannerEvent
            .region(
                planner: sourcePlanner,
                settings: settings,
                deviceLocation: deviceLocationManager.deviceLocation
            )
    }

    // TODO: no longer enforce this
    private var isLocationValid: Bool {
        !(draftPlannerEvent.hasTime && draftPlannerEvent.location == nil)
    }

    private var isCreateForm: Bool {
        initialPlannerEvent == nil && initialCalendarEvent == nil
    }

    private var canSave: Bool {
        !draftPlannerEvent.title.isEmpty && isLocationValid
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $draftPlannerEvent.title)
                        .textInputAutocapitalization(.words)
                }
                .listSectionMargins(.top, 0)

                Section {
                    DatePicker(
                        "Date",
                        selection: $draftPlannerEvent.date,
                        in: keepPastPlansDuration
                            .cutoffDate...todaystampWatcher
                            .maxCalendarDate,
                        displayedComponents: draftPlannerEvent.hasTime
                            ? [.date, .hourAndMinute] : .date
                    )
                    .environment(
                        \.timeZone,
                        eventRegion.timeZone
                    )

                    Toggle("Time", isOn: $draftPlannerEvent.hasTime)
                        .disabled(
                            !draftPlannerEvent.hasTime && defaultLocation == nil
                        )
                }

                Section {
                    NavigationLink {
                        LocationSearchView(
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
                            Text("Location")
                            Spacer()
                            Text(
                                draftPlannerEvent.location != nil
                                    ? draftPlannerEvent.locationLabel(
                                        planner: sourcePlanner,
                                        settings: settings,
                                        deviceLocation:
                                            deviceLocationManager
                                            .deviceLocation
                                    ) : "Select a location"  // TODO: say Planner location too
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(defaultLocation == nil)  // TODO: remove this
                } footer: {
                    if draftPlannerEvent.hasTime,
                        draftPlannerEvent.location != nil
                    {
                        let timeZoneAbbreviation =
                            draftPlannerEvent
                            .region(
                                planner: sourcePlanner,
                                settings: settings,
                                deviceLocation: deviceLocationManager
                                    .deviceLocation
                            )
                            .timeZone
                            .abbreviation() ?? "Unknown Time Zone"

                        Text("Time Zone: \(timeZoneAbbreviation)")
                    }
                }
            }
            .navigationTitle(isCreateForm ? "Create Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDisabled(true)
            .toolbar {
                saveButton
                addToCalendarButton
            }
        }
    }

    // MARK: - Toolbars

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
    private var addToCalendarButton: some ToolbarContent {
        if calendarStore.calendarAccessDenied == false {
            ToolbarItem(placement: .bottomBar) {
                ActionButtonView(
                    label: "Add To Calendar",
                    systemImage: "calendar.badge.plus",
                    onTap: addEventToCalendar
                )
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    private func savePlannerEvent() {

        modelContext.handlePlannerEventChange(
            draftPlannerEvent,
            previousDatestamp: sourcePlanner?.datestamp,
            targetDatestamp: DateInRegion(
                draftPlannerEvent.date,
                region: eventRegion
            ).datestamp,
            settings: settings,
            ekEventStore: calendarStore.ekEventStore,
            initialPlannerEvent: initialPlannerEvent,
            initialCalendarEvent: initialCalendarEvent
        )

        // Refresh calendar in case of recurring events.
        DispatchQueue.main.async {
            calendarStore.attemptFreshLoad(
                hiddenCalendarIds: settings.hiddenCalendarIds
            )
        }

        dismiss()
    }

    private func addEventToCalendar() {

        // Build a calendar event to represent the form values.
        let event =
            initialCalendarEvent
            ?? EKEvent(
                eventStore: calendarStore.ekEventStore
            )
        event.calendar =
            initialCalendarEvent?.calendar
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

        draftPlannerEvent.calendarEvent = event
        sheetDetent = .large
    }

}
