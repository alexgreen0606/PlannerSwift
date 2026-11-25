//
//  PlannerItem.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import Foundation

/// The in-memory row model shared by Planner-owned and EventKit-owned events.
struct PlannerItem: ListItem {
    typealias Draft = PlannerItemDraft
    
    enum Source {
        case plannerEvent(PlannerEvent)
        case ekEvent(event: EKEvent, state: EkEventPlannerState?)
    }

    let id: PlannerItemID
    let source: Source

    init(plannerEvent: PlannerEvent) {
        self.id = .plannerEvent(plannerEvent.stableId)
        self.source = .plannerEvent(plannerEvent)
    }

    init?(
        ekEvent: EKEvent,
        state: EkEventPlannerState?
    ) {
        guard let identity = EkEventIdentity(ekEvent: ekEvent) else {
            return nil
        }

        self.id = .ekEvent(identity)
        self.source = .ekEvent(event: ekEvent, state: state)
    }
}

// MARK: - Extension Helpers

extension PlannerItem {
    var title: String {
        switch source {
        case .plannerEvent(let event):
            event.title
        case .ekEvent(let event, state: _):
            event.title ?? ""
        }
    }

    var notes: String {
        switch source {
        case .plannerEvent(let event):
            event.notes
        case .ekEvent(let event, state: _):
            event.notes ?? ""
        }
    }

    var time: Date? {
        switch source {
        case .plannerEvent(let event):
            event.time
        case .ekEvent(let event, state: _):
            event.startDate
        }
    }

    var sortDate: Date {
        switch source {
        case .plannerEvent(let event):
            event.sortDate
        case .ekEvent(event: let ekEvent, let state):
            state?.sortDate ?? ekEvent.startDate
        }
    }

    var isCompleted: Bool {
        switch source {
        case .plannerEvent(let event):
            event.isCompleted
        case .ekEvent(event: _, let state):
            state?.isCompleted ?? false
        }
    }

    var allowsEditing: Bool {
        switch source {
        case .plannerEvent:
            true
        case .ekEvent(let event, state: _):
            event.calendar.allowsContentModifications
        }
    }

    var isCalendarEvent: Bool {
        switch source {
        case .plannerEvent:
            false
        case .ekEvent:
            true
        }
    }

    // MARK: Source Easy Access

    var plannerEvent: PlannerEvent? {
        if case .plannerEvent(let event) = source {
            return event
        }

        return nil
    }

    var ekEvent: EKEvent? {
        if case .ekEvent(let event, state: _) = source {
            return event
        }

        return nil
    }

    var ekEventPlannerState: EkEventPlannerState? {
        if case .ekEvent(event: _, let state) = source {
            return state
        }

        return nil
    }
}

// MARK: - Draft

/// An in-memory editing buffer for a `PlannerItem`.
///
/// `PlannerItem` is a lightweight struct that wraps either a `PlannerEvent` or an `EKEvent`,
///  Drafts are owned by `ListEngine` (keyed by `PlannerItemID`) so they survive row
///  re-creation while editing.
@Observable
final class PlannerItemDraft: ListItemDraft {
    var title: String = ""
    var notes: String = ""
    var time: Date?
    var datestamp: String?
    var isFlagged: Bool = false

    init(item: PlannerItem) {
        sync(from: item)
    }

    /// Updates this draft to match the item.
    func sync(from item: PlannerItem) {
        switch item.source {
        case .plannerEvent(let event):
            title = event.title
            notes = event.notes
            time = event.time
            datestamp = event.datestamp
            isFlagged = event.isFlagged

        case .ekEvent(let event, state: _):
            title = event.title ?? ""
            notes = event.notes ?? ""
            time = event.startDate
            datestamp = nil
            isFlagged = false
        }
    }

    /// Updates the item to match this draft.
    ///
    /// Note: Calendar events are only mutated in memory. Persisting the change to the
    /// `EKEventStore` is the responsibility of the list's `onCommitItem` handler.
    func commit(to item: PlannerItem) {
        let trimmedTitle = title.trimmed
        let trimmedNotes = notes.trimmed

        switch item.source {
        case .plannerEvent(let event):
            event.title = trimmedTitle
            event.notes = trimmedNotes
            event.time = time
            event.datestamp = datestamp
            event.isFlagged = isFlagged

        case .ekEvent(let event, state: _):
            // TODO: check when this is called. Likely this isn't needed except for title persistence.
            guard event.calendar.allowsContentModifications else { return }

            if event.title != trimmedTitle {
                event.title = trimmedTitle
            }

            if (event.notes ?? "") != trimmedNotes {
                event.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            }

            if !event.isAllDay,
                let time,
                let startDate = event.startDate,
                let endDate = event.endDate,
                time != startDate
            {
                // Preserve the event's duration when its start time changes.
                let duration = endDate.timeIntervalSince(startDate)
                event.startDate = time
                event.endDate = time.addingTimeInterval(duration)
            }
        }
    }

    /// Special handler called before creating new items.
    func commitTitle(to item: PlannerItem) {
        let trimmedTitle = title.trimmed

        switch item.source {
        case .plannerEvent(let event):
            event.title = trimmedTitle

        case .ekEvent(let event, state: _):
            // TODO: save the title here to event store?
            // or update the list to look at drafts, not actual items
            guard event.calendar.allowsContentModifications else { return }

            if event.title != trimmedTitle {
                event.title = trimmedTitle
            }
        }
    }
}
