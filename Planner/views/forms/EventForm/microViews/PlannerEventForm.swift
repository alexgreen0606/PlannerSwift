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
    let sourceCalendarEvent: EKEvent?
    let sourcePlannerEvent: PlannerEvent?
    let sourcePlanner: Planner?
    let sourceDay: DateInRegion?

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var notificationManager: NotificationManager
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
        sourcePlannerEvent == nil && sourceCalendarEvent == nil
    }

    private var canSave: Bool {
        !draftPlannerEvent.title.isEmpty
    }

    private var showTimeZoneFooter: Bool {
        sourcePlannerEvent?.hasTime == true
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
                titleSection
                timeSection
                locationSection
            }
            .animateSynchronousAction(from: draftPlannerEvent.hasTime)
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

    // MARK: - View Builders

    private var titleSection: some View {
        Section {
            TextField("Title", text: $draftPlannerEvent.title)
                .textInputAutocapitalization(.words)
        }
        .listSectionMargins(.top, 0)
    }

    private var timeSection: some View {
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
        }
    }

    private var locationSection: some View {
        Section {
            LabeledContent {
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
            } label: {
                Label("Location", systemImage: "mappin.and.ellipse")
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
        
        handleNotification(sourceDay: sourceDay, destinationDay: destinationDay)
    }
    
    private func handleNotification(
        sourceDay: DateInRegion?,
        destinationDay: DateInRegion?,
    ) {
        var config: NotificationConfig?

        if sourcePlanner == nil {
            if let destinationDay {
                config = NotificationConfig(
                    id: UUID(),
                    title: "Event created",
                    subtitle: "for \(destinationDay.dynamicHeader)",
                    iconConfig: IconConfig(
                        name: "checkmark",
                        primaryColor: Color.green
                    ),
                    onClick: {} // TODO: open the target planner here
                )
            }
        } else if let destinationDay {
            if destinationDay.datestamp != sourceDay?.datestamp {
                config = NotificationConfig(
                    id: UUID(),
                    title: "Event rescheduled",
                    subtitle: "for \(destinationDay.dynamicHeader)",
                    iconConfig: IconConfig(
                        name: "checkmark",
                        primaryColor: Color.green
                    ),
                    onClick: {} // TODO: open the target planner here
                )
            }
        }

        if let config {
            DispatchQueue.main.async {
                notificationManager.addNotification(config)
            }
        }
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

        draftPlannerEvent.calendarEvent = event
        sheetDetent = .large
    }

}
