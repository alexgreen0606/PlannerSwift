//
//  PlannerEventExtension.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate
import SwiftUI

// Clean

extension PlannerEvent {

    // MARK: - Location Variables

    private func location(
        planner: Planner?,
        settings: PlannerSettings,
        deviceLocation: Location?
    )
        -> Location?  // nil means the current device location is used and hasn't loaded yet
    {
        eventLocation(
            location: location,
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )
    }

    func region(
        planner: Planner?,
        settings: PlannerSettings,
        deviceLocation: Location?
    ) -> Region {
        location(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )?.region ?? .local
    }

    func locationLabel(
        planner: Planner?,
        settings: PlannerSettings,
        deviceLocation: Location?
    ) -> String {
        location(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )?.name ?? "Current Location"
    }
    
    // MARK: - Style Variables

    func tint(accentColor: AccentColor) -> Color {
        if let calendar = self.calendarEvent?.calendar {
            return calendar.color
        }

        return accentColor.color
    }

    // MARK: - Title Change Handlers

    func handleTitleChange(
        startOfDay: DateInRegion,
        eventKitStore: EKEventStore,
        defaultLocation: Location?
    ) {

        if let calendarEvent {
            // Event is a calendar event. Update its title in the calendar.
            calendarEvent.title = self.title

            do {
                try eventKitStore.save(
                    calendarEvent,
                    span: .thisEvent
                )
            } catch {
                assertionFailure(
                    "ERROR PlannerEventExtension.handleTitleChange: \(error)"
                )
            }

            return
        }

        // Scan the title for a date.
        guard let defaultLocation,
            let (date, updatedText) = self.title.separateDate(for: startOfDay)
        else {
            return
        }

        self.title = updatedText
        self.location = defaultLocation
        self.hasTime = true
        self.date = date

    }

    // MARK: - Data Modifiers

    func syncWithCalendarEvent(_ calendarEvent: EKEvent) {
        self.title = calendarEvent.title
        self.date = calendarEvent.startDate
        self.hasTime = true
        self.location = calendarEvent.location(
            storageEvent: self
        )
        self.calendarEvent = calendarEvent
        self.calendarItemExternalIdentifier =
            calendarEvent.calendarItemExternalIdentifier
        self.occurrenceId = calendarEvent.occurrenceId
    }

    // MARK: - View Builders

    @ViewBuilder
    func timeValueView(
        in plannerRegion: Region,
        accentColor: AccentColor,
        scale: Double = 1,
        openSheet: (() -> Void)?
    ) -> some View {
        if self.hasTime {
            TimeView(
                timeInRegion: DateInRegion(self.date, region: plannerRegion),
                color: self.tint(accentColor: accentColor),
                scale: scale,
                openEventSheet: openSheet
            )
        }
    }

    @ViewBuilder
    func locationValueView(
        in planner: Planner,
        settings: PlannerSettings,
        deviceLocation: Location?,
        accentColor: AccentColor,
        openEventSheet: @escaping () -> Void
    ) -> some View {

        // Planner Info.
        let plannerRegion = planner.region(settings: settings)
        let plannerTimeZoneIdentifier = plannerRegion.timeZone.identifier
        let plannerLocationLabel = planner.locationLabel(
            settings: settings,
            deviceLocation: deviceLocation
        )

        // Event Info.
        let eventRegion = region(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )
        let eventTimeZoneIdentifier = eventRegion.timeZone.identifier
        let eventLocationLabel = self.locationLabel(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )

        let isLocationLabelDifferent =
            eventLocationLabel != plannerLocationLabel
        let isTimeZoneDifferent =
            eventTimeZoneIdentifier != plannerTimeZoneIdentifier

        // Assemble the event labels if they differ from the planner.

        let locationText: String? = {
            if isLocationLabelDifferent {
                return eventLocationLabel
            }
            return nil
        }()

        let timeText: String? = {
            if isTimeZoneDifferent, hasTime {
                return DateInRegion(
                    date,
                    region: eventRegion
                ).timeWithTimezone
            }
            return nil
        }()

        EventBottomAdornmentView(
            iconConfig: IconConfig(
                name: "mappin.and.ellipse",
                primaryColor: accentColor.color
            ),
            locationLabel: locationText,
            timeLabel: timeText,
            openEventSheet: openEventSheet
        )
    }

}
