//
//  _RoutineEvent.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftDate
import SwiftUI

// Clean

struct NeighborIds {
    var upperId: UUID?
    var lowerId: UUID?
}

extension RoutineEvent {

    var daysOfWeek: Set<DayOfWeek> {
        Set(self.sortDateMap.keys)
    }

    func syncWithDraftRoutineEvent(
        _ draft: DraftRoutineEvent
    ) {
        self.title = draft.title
        self.time = draft.hasTime ? draft.date : nil
    }

    func getNeighborIds(
        in sortedRoutineEvents: [RoutineEvent]
    ) -> NeighborIds {

        guard
            let index = sortedRoutineEvents.firstIndex(where: {
                $0.stableId == self.stableId
            })
        else {
            return NeighborIds(upperId: nil, lowerId: nil)
        }

        let upperId =
            index > 0
            ? sortedRoutineEvents[index - 1].stableId
            : nil

        let lowerId =
            index < sortedRoutineEvents.count - 1
            ? sortedRoutineEvents[index + 1].stableId
            : nil

        return NeighborIds(upperId: upperId, lowerId: lowerId)
    }

    @ViewBuilder
    func timeAdornment(
        dayOfWeek: DayOfWeek,
        accentColor: AccentColor,
        scale: Double = 1,
        openEventSheet: (() -> Void)?
    ) -> some View {
        // if let time = self.time {
            TimeView(
                timeInRegion: DateInRegion(self.sortDateMap[dayOfWeek]!, region: .UTC),
                color: accentColor.color,
                scale: scale,
                openEventSheet: openEventSheet
            )
        // }
    }

    @ViewBuilder
    func recurringAdornment(
        openEventSheet: (() -> Void)?
    ) -> some View {
        if sortDateMap.keys.count > 1 {
            DayOfWeekSpreadView(
                selected: self.daysOfWeek,
                scale: 0.66,
                spacing: 1
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                openEventSheet?()
            }
        }
    }

}
