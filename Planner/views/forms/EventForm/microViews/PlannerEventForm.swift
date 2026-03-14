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

    private var isCreateForm: Bool {
        initialPlannerEvent == nil && initialCalendarEvent == nil
    }

    private var canSave: Bool {
        !draftPlannerEvent.title.isEmpty
    }

    private var showTimeZoneFooter: Bool {
        initialPlannerEvent?.hasTime == true
    }

    private var timeZoneAbbreviation: String {
        return
            draftPlannerEvent
            .region(
                planner: sourcePlanner,
                settings: settings,
                deviceLocation: deviceLocationManager
                    .deviceLocation
            )
            .timeZone
            .abbreviation() ?? "Unknown Time Zone"
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
                    LabeledContent {
                        DatePicker(
                            "",
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
                    } label: {
                        Label("Date", systemImage: "calendar")
                            .foregroundStyle(Color.label)
                    }
                    .animation(nil, value: draftPlannerEvent.hasTime)

                    LabeledContent {
                        Toggle("", isOn: $draftPlannerEvent.hasTime)
                    } label: {
                        Label("Time", systemImage: "clock")
                            .foregroundStyle(Color.label)
                    }

                    if !showTimeZoneFooter && draftPlannerEvent.hasTime {
                        LabeledContent {
                            Text(timeZoneAbbreviation)
                        } label: {
                            Label("Time Zone", systemImage: "globe")
                                .foregroundStyle(Color.label)
                        }
                    }
                } footer: {
                    if showTimeZoneFooter && draftPlannerEvent.hasTime {
                        HStack(alignment: .bottom, spacing: 4) {
                            Text("Time Zone:")
                            Text(timeZoneAbbreviation)
                                .font(
                                    .system(
                                        size: 14,
                                        weight: .black,
                                        design: .rounded
                                    )
                                )
                        }
                    }
                }

                Section {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .imageScale(.medium)

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
                                        ) : "Set a location"
                                )
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
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
            .animateSynchronousAction(from: draftPlannerEvent.hasTime)
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

    // MARK: - Functions

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
