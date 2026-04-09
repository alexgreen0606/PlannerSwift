//
//  _RoutineEvent.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftDate
import SwiftUI

// Clean

extension RoutineEvent {

    var weekdays: Set<Weekday> {
        Set(self.sortDateMap.keys)
    }

    func syncWithDraftRoutineEvent(
        _ draft: DraftRoutineEvent
    ) {
        self.title = draft.title
        self.time = draft.hasTime ? draft.date : nil
    }

    // MARK: - View Builders

    @ViewBuilder
    func timeAdornment(
        accentColor: AccentColor,
        openEventSheet: (() -> Void)?
    ) -> some View {
        if let time = self.time {
            TimeView(
                timeInRegion: DateInRegion(time, region: .UTC),
                color: accentColor.color,
                openEventSheet: openEventSheet
            )
        }
    }

    @ViewBuilder
    func weekdaysAdornment(
        openEventSheet: (() -> Void)?
    ) -> some View {
        if sortDateMap.keys.count > 1 {
            WeekdaySpreadView(
                selected: self.weekdays,
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
