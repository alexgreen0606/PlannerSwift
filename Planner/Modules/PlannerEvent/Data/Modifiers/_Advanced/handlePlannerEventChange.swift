//
//  handlePlannerEventChange.swift
//  Planner
//
//  Created by Alex Green on 4/2/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {
    @MainActor
    func handlePlannerEventChange(
        _ plannerEvent: PlannerEvent,
        in planner: Planner,
        startOfDay: DateInRegion,
        plannerLocation: Location?,
        todaystamp: String,
        ekEventStore: EKEventStore,
        showToast: (Toast) -> Void,
        plannerCoverStore: PlannerCoverStore,
        settings: Settings
    ) {
        if plannerEvent.eKEventContext != nil {
            // MARK: Event is a calendar event. Update its title in the calendar.

            guard
                let ekEvent = ekEventStore.getEkEvent(for: plannerEvent),
                ekEvent.calendar.allowsContentModifications
            else {
                return
            }

            ekEvent.title = plannerEvent.title

            _ = ekEventStore.attemptUpdateEvent(ekEvent)

            return
        }

        if let plannerLocation,
            let (time, updatedText) = plannerEvent.title.extractTime(
                for: startOfDay
            ),
            !updatedText.isEmpty
        {
            // MARK: Title has a time value. Re-configure the event.
            plannerEvent.title = updatedText
            plannerEvent.location = plannerLocation
            plannerEvent.time = time
        }

        // MARK: Update the event's routine variance.
        plannerEvent.updateRoutineVariance(
            in: startOfDay.region.timeZone,
            settings: settings
        )

        // MARK: Place the event in its planner if it moved due to flagging.

        let todayPlanner = getPlanner(for: todaystamp)

        let datestamps = ensureValidPlannerEventPosition(
            for: plannerEvent,
            sourceDatestamp: planner.datestamp,
            todayStartOfDay: todayPlanner.startOfDay(settings: settings),
            settings: settings
        )

        safeSave("handlePlannerEventChange")

        // Display a toast if the event has moved.
        if !datestamps.contains(planner.datestamp),
            let datestamp = datestamps.first
        {
            showToast(
                Toast(
                    title:
                        "Event carried to \(datestamp.countdown(todaystamp: todaystamp).lowercased())!",
                    subtitle:
                        "\(datestamp.dateWithYear) | \(datestamp.weekday)",
                    iconConfig: IconConfig(
                        name: "arrow.left.arrow.right",
                        primaryColor: Color.label
                    ),
                    action: {
                        plannerCoverStore.context = PlannerCoverContext(
                            datestamp: todaystamp
                        )
                    }
                )
            )
        }
    }
}
