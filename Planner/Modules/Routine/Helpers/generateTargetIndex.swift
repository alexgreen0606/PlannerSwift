//
//  generateTargetIndex.swift
//  Planner
//
//  Created by Alex Green on 4/8/26.
//

import SwiftUI

/// Finds a position for a recurring event that places it close as possible to its siblings.
func generateRoutineEventIndex<Destination: EventListItem>(
    near sourceId: UUID,
    from sortedSourceEvents: [RoutineEvent],
    to sortedDestinationEvents: [Destination],
    destinationComparatorId: (Destination) -> UUID? = { $0.stableId }
) -> Int {
    // MARK: Find current index in source.

    guard
        let sourceIndex = sortedSourceEvents.firstIndex(where: {
            $0.stableId == sourceId
        })
    else {
        // Fallback to top of list if source not found.
        return 0
    }

    let maxDistance = sortedSourceEvents.count

    // MARK: Expand outward to find a neighbor that exists in the new destination.

    for distance in 1 ..< maxDistance {
        // Check if upper neighbor exists in the destination.
        let upperIndex = sourceIndex - distance
        if upperIndex >= 0 {
            let upperId = sortedSourceEvents[upperIndex].stableId

            if let destIndex = sortedDestinationEvents.firstIndex(
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
        if lowerIndex < sortedSourceEvents.count {
            let lowerId = sortedSourceEvents[lowerIndex].stableId

            if let destIndex = sortedDestinationEvents.firstIndex(
                where: {
                    destinationComparatorId($0) == lowerId
                }
            ) {
                // MARK: Place above the lower neighbor.

                return destIndex
            }
        }
    }

    return 0
}
