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

    @ViewBuilder
    func timeAdornment(
        dayOfWeek: DayOfWeek,
        accentColor: AccentColor,
        scale: Double = 1,
        openEventSheet: (() -> Void)?
    ) -> some View {
        if let time = self.time {
            TimeView(
                timeInRegion: DateInRegion(time, region: .UTC),
                color: accentColor.color,
                scale: scale,
                openEventSheet: openEventSheet
            )
        }
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
