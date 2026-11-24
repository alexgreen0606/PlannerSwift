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
    /// Calendar events only receive an `EkEventPlannerState` once the user changes Planner-only data,
    /// so one is created lazily (at the item's current position) the first time the event is toggled.
    ///
    /// // TODO: this isnt true. This state should be created immediately for new events so that they can be force-placed at the top of the planner.
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
