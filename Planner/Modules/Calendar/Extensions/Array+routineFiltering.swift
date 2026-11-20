//
//  Array+routineFiltering.swift
//  Planner
//
//  Created by Alex Green on 11/20/26.
//

extension Array where Element == PlannerEvent {
    func filterOutRoutineUnlessSearching(
        activeQuery: PlannerSearchQuery?
    ) -> [PlannerEvent] {
        guard activeQuery == nil || activeQuery!.isDefault else {
            return self
        }

        return filter {
            guard let routineContext = $0.routineEventRecordContext else {
                return true
            }

            return routineContext.isVariant
        }
    }
}
