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

    // MARK: - Location Helpers

    // Nil means the current device location is used.
    private func location(settings: PlannerSettings, planner: Planner?)
        -> Location?
    {
        eventLocation(
            locationSource: locationSource,
            location: location,
            planner: planner,
            settings: settings
        )
    }

    func locationIconConfig(
        settings: PlannerSettings,
        planner: Planner,
        accentColor: AccentColor
    )
        -> IconConfig
    {
        switch locationSource {
        case .custom:
            return IconConfig(
                name: "mappin.and.ellipse",
                primaryColor: accentColor.swiftUIColor,
                secondaryColor: Color.secondary
            )
        case .home:
            return settings.homeLocationIconConfig
        case .current:
            return IconConfig(
                name: "Location",
                primaryColor: Color.secondary,
                secondaryColor: nil
            )
        case .planner:
            return planner.locationIconConfig(
                settings: settings,
                accentColor: accentColor
            )
        }
    }

    func region(settings: PlannerSettings, planner: Planner?) -> Region {
        location(settings: settings, planner: planner)?.region ?? .local
    }

    func locationLabel(
        localCityName: String,
        settings: PlannerSettings,
        planner: Planner?
    ) -> String {
        location(settings: settings, planner: planner)?.name ?? localCityName
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
        eventKitStore: EKEventStore
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
        guard
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
        localCityName: String,
        accentColor: AccentColor
    ) -> some View {

        let plannerRegion = planner.region(settings: settings)

        if let calendarEvent,
            let values = calendarEvent.bottomAdornmentValues(
                plannerRegion: plannerRegion
            )
        {
            HStack {

                if let location = values.location {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 10, height: 10)
                            .foregroundStyle(
                                calendarEvent.calendar.color,
                                Color.secondary
                            )

                        Text(location)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let time = values.time {
                    Text(time)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)
        }

        let eventRegion = region(settings: settings, planner: planner)
        let locationLabel = locationLabel(
            localCityName: localCityName,
            settings: settings,
            planner: planner
        )
        let plannerLocationLabel = planner.locationLabel(
            localCityName: localCityName,
            settings: settings
        )

        if locationLabel != plannerLocationLabel {
            HStack {

                let iconConfig = locationIconConfig(
                    settings: settings,
                    planner: planner,
                    accentColor: accentColor
                )

                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: iconConfig.name)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundStyle(
                            iconConfig.primaryColor ?? Color.secondary,
                            iconConfig.secondaryColor ?? Color.secondary
                        )

                    Text(locationLabel)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                if eventRegion != plannerRegion && hasTime {
                    let dateInRegion = DateInRegion(date, region: eventRegion)
                    let timeString =
                        dateInRegion.timeWithTimezone ?? "Unknown Time Zone"

                    Text(timeString)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 4)
        }
    }

}
