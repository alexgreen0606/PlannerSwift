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

    func locationIconConfig(
        settings: PlannerSettings,
        accentColor: AccentColor
    )
        -> IconConfig
    {
        if let homeLocation = settings.homeLocation, location == homeLocation {
            return IconConfig(name: "house")
        }

        return IconConfig(
            name: "mappin.and.ellipse",
            primaryColor: accentColor.swiftUIColor
        )
    }

    // MARK: - Style Helpers

    func tint(accentColor: AccentColor) -> Color {
        if let calendar = self.calendarEvent?.calendar {
            return calendar.color
        }

        return accentColor.swiftUIColor
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
            let (timeValue, updatedText) = self.title.separateTimeValue()
        else {
            return
        }

        guard
            let date = timeValue.toDate(
                for: startOfDay
            )
        else {
            return
        }

        self.title = updatedText
        self.location = defaultLocation
        self.hasTime = true

        // Change the event's date, but preserve its sort position.
        self.date = date

    }

    // MARK: - View Builders

    @ViewBuilder
    func timeValueView(
        in plannerRegion: Region,
        accentColor: AccentColor,
        openSheet: (() -> Void)?
    ) -> some View {
        if let calendarEvent {

            calendarEvent.timeValueView(
                in: plannerRegion,
                openSheet: openSheet
            )

        } else if self.hasTime {

            TimeValueView(
                day: DateInRegion(self.date, region: plannerRegion),
                disabled: false,
                color: accentColor.swiftUIColor,
                scale: 1,
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
        let plannerLocationLabel = planner.locationLabel(
            settings: settings,
            deviceLocation: deviceLocation
        )

        // --- Calendar Event Case ---
        if let calendarEvent,
            let values = calendarEvent.bottomAdornmentValues(
                plannerRegion: plannerRegion,
                plannerLocationLabel: plannerLocationLabel
            )
        {
            LocationBottomAdornmentView(
                icon: IconConfig(
                    name: "mappin.and.ellipse",
                    primaryColor: calendarEvent.calendar.color
                ),
                locationText: values.location,
                timeText: values.time,
                openEventSheet: openEventSheet
            )
        }

        // --- Planner Event Case ---
        let eventRegion = region(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )

        let locationLabel = locationLabel(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )

        if locationLabel != plannerLocationLabel {

            let timeString: String? = {
                if eventRegion != plannerRegion, hasTime {
                    return DateInRegion(date, region: eventRegion)
                        .timeWithTimezone
                }
                return nil
            }()

            LocationBottomAdornmentView(
                icon: locationIconConfig(
                    settings: settings,
                    accentColor: accentColor
                ),
                locationText: locationLabel,
                timeText: timeString,
                openEventSheet: openEventSheet
            )
        }
    }

}
