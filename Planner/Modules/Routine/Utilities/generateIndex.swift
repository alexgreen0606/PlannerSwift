//
//  generateIndex.swift
//  Planner
//
//  Created by Alex Green on 4/8/26.
//

import SwiftData
import SwiftUI

// MARK: - Routine Event Caller
@MainActor
func generateRoutineEventIndex(
    near sourceId: UUID,
    from sourceSortedRoutineEvents: [RoutineEvent],
    to destinationSortedRoutineEvents: [RoutineEvent]
) -> Int {
    return generateIndex(
        near: sourceId,
        from: sourceSortedRoutineEvents,
        to: destinationSortedRoutineEvents,
        destinationComparatorId: {
            $0.routineEventContext?.stableId
        }
    )
}

// MARK: Planner Event Caller
@MainActor
func generateRoutineRecordIndex(
    near sourceId: UUID,
    from sourceSortedRoutineEvents: [RoutineEvent],
    to destinationSortedRoutineEvents: [PlannerEvent]
) -> Int {
    return generateIndex(
        near: sourceId,
        from: sourceSortedRoutineEvents,
        to: destinationSortedRoutineEvents,
        destinationComparatorId: {
            $0.routineEventRecordContext?.routineEvent?
                .routineEventContext?.stableId
        }
    )
}

// MARK: - Generation Logic

/// Finds a position for an event that places it close as possible to its siblings.
@MainActor
private func generateIndex<DestinationEvent: PersistentModel>(
    near sourceId: UUID,
    /// These are the events in the routine where the routine event exists.
    from sourceSortedRoutineEvents: [RoutineEvent],
    /// These are the events in the routine or planner where the event is being placed.
    to destinationSortedRoutineEvents: [DestinationEvent],
    destinationComparatorId: @MainActor (DestinationEvent) -> UUID?
) -> Int {
    // MARK: Find current index in source.
    guard
        let sourceIndex = sourceSortedRoutineEvents.firstIndex(where: {
            $0.routineEventContext?.stableId == sourceId
        })
    else {
        // Fallback to top of list if source not found.
        return 0
    }

    let maxDistance = sourceSortedRoutineEvents.count

    // MARK: Expand outward to find a neighbor that exists in the new destination.

    for distance in 1..<maxDistance {
        // Check if upper neighbor exists in the destination.
        let upperIndex = sourceIndex - distance
        if upperIndex >= 0 {
            let upperId = sourceSortedRoutineEvents[upperIndex]
                .routineEventContext?.stableId

            if let destIndex = destinationSortedRoutineEvents.firstIndex(
                where: {
                    destinationComparatorId($0) == upperId
                }
            ) {
                // MARK: Place below the upper neighbor.
                return destIndex + 1
            }
        }

        // Check if lower neighbor exists in the destination.
        let lowerIndex = sourceIndex + distance
        if lowerIndex < sourceSortedRoutineEvents.count {
            let lowerId = sourceSortedRoutineEvents[lowerIndex]
                .routineEventContext?.stableId

            if let destIndex = destinationSortedRoutineEvents.firstIndex(
                where: {
                    destinationComparatorId($0) == lowerId
                }
            ) {
                // MARK: Place above the lower neighbor.
                return destIndex
            }
        }
    }

    // No sibling was found. Place at the top of the list.
    return 0
}
