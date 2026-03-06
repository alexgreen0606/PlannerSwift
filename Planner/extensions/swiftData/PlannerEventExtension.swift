//
//  PlannerEventExtension.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate
import SwiftUI

extension PlannerEvent {

    // MARK: - Location Variables

    // Nil means the current device location is used.
    private func location(
        planner: Planner?,
        settings: PlannerSettings,
        deviceLocation: Location?
    )
        -> Location?
    {
        eventLocation(
            location: location,
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )
    }

    func existsInRange(start: Date, end: Date) -> Bool {
        if !hasTime {
            return date == start.date
        }

        return date >= start && date < end
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

    // MARK: - Style Helpers

    func tint(accentColor: AccentColor) -> Color {
        if let calendar = self.calendarEvent?.calendar {
            return calendar.color
        }

        return accentColor.color
    }

    // MARK: - Title Change Helper

    func handleTitleChange(
        startOfDay: DateInRegion,
        eventKitStore: EKEventStore,
        defaultLocation: Location?
    ) {

        // Case 1: Update the device calendar with the new title.
        guard self.calendarEvent == nil else {
            self.calendarEvent!.title = self.title

            do {
                try eventKitStore.save(
                    self.calendarEvent!,
                    span: .thisEvent
                )
            } catch {
                assertionFailure(
                    "ERROR PlannerEventExtension.handleTitleChange: \(error)"
                )
            }

            return
        }

        // Case 2: Scan the new title for a time value.
        guard let defaultLocation,
              let (date, updatedText) = self.title.separateDate(for: startOfDay)
        else {
            return
        }

        self.title = updatedText
        self.location = defaultLocation
        self.hasTime = true

        // Change the event's date, but preserve its sort position.
        self.date = date

    }

    // MARK: - Calendar Helpers

    func syncWithCalendarEvent(_ calendarEvent: EKEvent) {
        self.title = calendarEvent.title
        self.date = calendarEvent.startDate
        self.location = calendarEvent.location(
            storageEvent: self
        )
        self.calendarEvent = calendarEvent
        self.calendarItemExternalIdentifier =
            calendarEvent.calendarItemExternalIdentifier
        self.occurrenceId = calendarEvent.occurrenceId
        self.hasTime = true
    }

    // MARK: - View Builders

    @ViewBuilder
    func timeValueView(
        in plannerRegion: Region,
        accentColor: AccentColor,
        scale: Double = 1,
        openSheet: (() -> Void)?
    ) -> some View {
        if let calendarEvent {

            calendarEvent.timeValueView(
                in: plannerRegion,
                scale: scale,
                openSheet: openSheet
            )

        } else if self.hasTime {

            TimeValueView(
                timeInRegion: DateInRegion(self.date, region: plannerRegion),
                color: accentColor.color,
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

        let plannerRegion = planner.region(settings: settings)
        let plannerTimeZoneIdentifier = plannerRegion.timeZone.identifier
        let plannerLocationLabel = planner.locationLabel(
            settings: settings,
            deviceLocation: deviceLocation
        )

        // --- Calendar Event Case ---
//        if let calendarEvent,
//            let values = calendarEvent.bottomAdornmentValues(
//                plannerRegion: plannerRegion,
//                plannerLocationLabel: plannerLocationLabel
//            )
//        {
//            LocationBottomAdornmentView(
//                icon: IconConfig(
//                    name: "mappin.and.ellipse",
//                    primaryColor: calendarEvent.calendar.color
//                ),
//                locationText: values.location,
//                timeText: values.time,
//                openEventSheet: openEventSheet
//            )
//        }

        // --- Planner Event Case ---
        let eventRegion = region(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )
        
        let eventTimeZoneIdentifier = eventRegion.timeZone.identifier

        let eventLocationLabel = locationLabel(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )

        if eventLocationLabel != plannerLocationLabel || eventTimeZoneIdentifier != plannerTimeZoneIdentifier {

            let timeString: String? = {
                if hasTime {
                    return DateInRegion(
                        date,
                        region: eventRegion
                    ).timeWithTimezone
                }
                return nil
            }()

            LocationBottomAdornmentView(
                icon: IconConfig(
                    name: "mappin.and.ellipse",
                    primaryColor: accentColor.color
                ),
                locationText: eventLocationLabel,
                timeText: timeString,
                openEventSheet: openEventSheet
            )
        }
    }

}
