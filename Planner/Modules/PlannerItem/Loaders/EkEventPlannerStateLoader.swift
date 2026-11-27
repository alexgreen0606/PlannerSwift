//
//  EkEventPlannerStateLoader.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import SwiftData
import SwiftUI

/// How `EkEventPlannerStateLoaderView` queries the persisted states.
enum EkEventPlannerStateMatching {
    /// One exact (identifier, occurrence) predicate per event.
    /// Precise, but the predicate grows with the event count. Best for a single planner.
    case exactOccurrences
    /// Every state for the events' identifiers (any occurrence), matched to occurrences in memory.
    /// Keeps the predicate small for large ranges, such as a calendar month.
    case externalIdentifiers
}

/// Pairs each calendar event with its persisted Planner state (if any).
struct EkEventPlannerStateLoaderView<Content: View>: View {
    private let ekEvents: [EKEvent]
    private let content: ([PlannerItem]) -> Content

    init(
        ekEvents: [EKEvent],
        matching: EkEventPlannerStateMatching = .exactOccurrences,
        @ViewBuilder content: @escaping ([PlannerItem]) -> Content
    ) {
        self.ekEvents = ekEvents
        self.content = content

        let predicate: Predicate<EkEventPlannerState> =
            switch matching {
            case .exactOccurrences:
                EkEventPlannerState.matching(ekEvents: ekEvents)
            case .externalIdentifiers:
                EkEventPlannerState.matching(
                    externalIdentifiers: Array(
                        Set(
                            ekEvents.compactMap(
                                \.calendarItemExternalIdentifier
                            )
                        )
                    )
                )
            }

        _states = Query(filter: predicate)
    }

    @Query private var states: [EkEventPlannerState]

    private var items: [PlannerItem] {
        let statesByExternalIdentifier = Dictionary(
            grouping: states,
            by: \.externalIdentifier
        )

        return ekEvents.compactMap { ekEvent in
            let state = statesByExternalIdentifier[
                ekEvent.calendarItemExternalIdentifier
            ]?.first {
                $0.recurrenceOccurrenceDate == ekEvent.occurrenceDate
            }

            return PlannerItem(
                ekEvent: ekEvent,
                state: state
            )
        }
    }

    // MARK: - Body

    var body: some View {
        content(items)
    }
}
