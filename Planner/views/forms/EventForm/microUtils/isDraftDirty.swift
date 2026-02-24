//
//  isDraftDirty.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

func isDraftDirty(draft: DraftPlannerEvent, initial: PlannerEvent?) -> Bool {
    draft.date != initial?.date
        || draft.title != initial?.title
        || draft.calendarEvent != initial?.calendarEvent
        || draft.hasTime != initial?.hasTime
        || draft.location != initial?.location
        || draft.locationSource != initial?.locationSource
}
