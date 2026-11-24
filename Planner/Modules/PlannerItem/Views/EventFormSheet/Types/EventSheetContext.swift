//
//  EventSheetContext.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit

/// Describes the event sheet presented for a `PlannerItem`.
/// The sheet's identity is the item, so switching forms cross-fades within the same sheet.
struct EventSheetContext: Identifiable {
    enum Form {
        /// The Planner-owned form.
        case planner(draft: DraftPlannerEvent)
        /// The editable calendar form.
        /// The Planner draft is carried along so "Remove from Calendar" can restore it.
        case calendar(ekEvent: EKEvent, plannerDraft: DraftPlannerEvent?)
        /// A read-only calendar event.
        case viewCalendar(ekEvent: EKEvent)
    }

    let item: PlannerItem

    /// The form shown when the sheet opens.
    let initialForm: Form

    init(item: PlannerItem, form: Form) {
        self.item = item
        self.initialForm = form
    }

    /// Picks the starting form for an item.
    init(
        item: PlannerItem,
        planner: Planner,
        ekEventStore: EKEventStore,
        settings: Settings
    ) {
        switch item.source {
        case .plannerEvent(let plannerEvent):
            self.init(
                item: item,
                form: .planner(
                    draft: DraftPlannerEvent(
                        plannerEvent: plannerEvent,
                        planner: planner,
                        ekEventStore: ekEventStore,
                        settings: settings
                    )
                )
            )

        case .ekEvent(let ekEvent, state: _):
            self.init(
                item: item,
                form: ekEvent.calendar.allowsContentModifications
                    ? .calendar(ekEvent: ekEvent, plannerDraft: nil)
                    : .viewCalendar(ekEvent: ekEvent)
            )
        }
    }
}

// MARK: - Helper Extension

extension EventSheetContext {
    var id: PlannerItem.ID {
        item.id
    }
}
