//
//  PlannerExtension.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftUI

extension Planner {

    func location(settings: PlannerSettings?) -> Location? {
        if self.locationSource == .custom,
            let plannerLocation = self.location
        {
            return plannerLocation
        }

        if self.locationSource == .home,
            let homeLocation = settings?.homeLocation
        {
            return homeLocation
        }

        // Nil uses the device location.
        return nil
    }

    func locationLabel(settings: PlannerSettings?, localCityName: String?)
        -> String?
    {
        if self.locationSource == .custom,
            let plannerLocation = self.location
        {
            return plannerLocation.name
        }

        if self.locationSource == .home,
            let homeLocation = settings?.homeLocation
        {
            return homeLocation.name
        }

        return localCityName
    }

    func locationIconConfig(
        settings: PlannerSettings?,
        accentColor: AccentColor
    ) -> IconConfig {
        if self.locationSource == .custom,
            self.location != nil
        {
            return IconConfig(
                name: "mappin.and.ellipse",
                primaryColor: accentColor.swiftUIColor,
                secondaryColor: Color(uiColor: .secondaryLabel)
            )
        }

        if self.locationSource == .home,
            settings?.homeLocation != nil
        {
            return IconConfig(
                name: "house",
                primaryColor: Color(uiColor: .secondaryLabel),
                secondaryColor: nil
            )
        }

        return IconConfig(
            name: "location",
            primaryColor: Color(uiColor: .secondaryLabel),
            secondaryColor: nil
        )
    }

    func synchronizeCalendarEventPositions(
        for calendarEvents: [EKEvent],
        from settings: CalendarSettings
    ) -> [PlannerEvent] {

        var sortedPlannerEvents = self.events.filter { !$0.isChecked }.sorted {
            $0.sortIndex < $1.sortIndex
        }

        let sortedCalendarEvents = calendarEvents.sorted {
            $0.startDate < $1.startDate
        }

        var plannerEvents: [PlannerEvent] = []

        for calEvent in sortedCalendarEvents {
            let sortIndex =
                settings.sortIndexMap[calEvent.calendarItemExternalIdentifier]
                ?? ((sortedPlannerEvents.last?.sortIndex ?? 0) + 8)

            // Dummy event for UI representation. No persistence to storage.
            let plannerEvent = PlannerEvent(
                sortIndex: sortIndex,
                calendarEvent: calEvent
            )

            sortedPlannerEvents.append(plannerEvent)

            plannerEvent.sortIndex = generateValidPlannerEventSortIndex(
                for: plannerEvent,
                in: sortedPlannerEvents
            )

            plannerEvents.append(plannerEvent)
            settings.sortIndexMap[calEvent.calendarItemExternalIdentifier] =
                plannerEvent.sortIndex
        }

        return plannerEvents
    }

}
