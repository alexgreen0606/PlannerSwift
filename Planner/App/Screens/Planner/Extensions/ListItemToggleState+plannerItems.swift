//
//  ListItemToggleState+plannerItems.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import SwiftData

extension ListItemToggleState where Item == PlannerItem {
    /// Toggles completion for both Planner-owned and EventKit-owned items.
    ///
    /// Timed calendar events receive an `EkEventPlannerState` as soon as their planner loads
    /// (see `ModelContext.placeNewEkEventItems`). As a fallback (e.g. a toggle before that state
    /// is picked up), one is created at the item's current position.
    static func completion(
        modelContext: @escaping () -> ModelContext?
    ) -> ListItemToggleState<PlannerItem> {
        ListItemToggleState(
            isToggled: { $0.isCompleted },
            setIsToggled: { item, isCompleted in
                switch item.source {
                case .plannerEvent(let event):
                    event.isCompleted = isCompleted

                case .ekEvent(let ekEvent, let state):
                    if let state {
                        state.isCompleted = isCompleted
                        return
                    }

                    guard let modelContext = modelContext() else { return }

                    modelContext.ensureEkEventPlannerState(
                        for: ekEvent,
                        sortDate: item.sortDate
                    ).isCompleted = isCompleted
                }
            }
        )
    }
}
