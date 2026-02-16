//
//  PlannerExtension.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate
import SwiftUI

extension Planner {
    
    var key: String {
        location?.key ?? "\(datestamp)-CURRENT_LOCATION"
    }

    func region(settings: PlannerSettings?) -> Region {
        location(settings: settings)?.region ?? .local
    }

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

        return localCityName ?? "Current Location"
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
                secondaryColor: Color.secondary
            )
        }

        if self.locationSource == .home,
            settings?.homeLocation != nil
        {
            return IconConfig(
                name: "house",
                primaryColor: Color.secondary,
                secondaryColor: nil
            )
        }

        return IconConfig(
            name: "location",
            primaryColor: Color.secondary,
            secondaryColor: nil
        )
    }

    // TODO: should I just sort ALL calendar events with ALL planner events? Is that a crazy idea?
    
    // TODO: get this working. Is casting to region important here? Or is the creation of the events at the correct region what matters, and this is simply sorting absolute positions?
    func synchronizeCalendarEventPositions(
        _ calendarEvents: [EKEvent],
        plannerEvents: [PlannerEvent], // Note: This should have all plans, not just open ones.
        calendarSettings: CalendarSettings,
        plannerSettings: PlannerSettings
    ) -> [PlannerEvent] {
        
        // TODO: do regions even matter here?
        let plannerRegion = self.region(settings: plannerSettings)
        
        // Calendar events use their regions from EKEvent?

        var sortedPlannerEvents: [PlannerEvent] = plannerEvents.sorted {
            $0.sortIndex < $1.sortIndex
        }

        let sortedCalendarEvents = calendarEvents.sorted {
            $0.startDate < $1.startDate
        }

        var plannerEvents: [PlannerEvent] = []

        for calEvent in sortedCalendarEvents {
            let sortIndex =
                calendarSettings.sortIndexMap[calEvent.calendarItemExternalIdentifier]
                ?? ((sortedPlannerEvents.last?.sortIndex ?? 0) + 8)

            // Dummy event for UI representation. No persistence to storage.
            let plannerEvent = PlannerEvent(
                date: calEvent.startDate, // TODO: use end date if this is an end date
                calendarEvent: calEvent,
                sortIndex: sortIndex
            )

            sortedPlannerEvents.append(plannerEvent)

            plannerEvent.sortIndex = generateValidPlannerEventSortIndex(
                for: plannerEvent,
                in: sortedPlannerEvents
            )

            plannerEvents.append(plannerEvent)
            calendarSettings.sortIndexMap[calEvent.calendarItemExternalIdentifier] =
                plannerEvent.sortIndex
        }

        return plannerEvents
    }

}
