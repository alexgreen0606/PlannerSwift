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

    func syncWithRecurringRoutineEvent(
        _ recurringRoutineEvent: RecurringRoutineEvent
    ) {
        guard !self.isException else { return }

        self.title = recurringRoutineEvent.title
        self.time = recurringRoutineEvent.time
        self.recurringParent = recurringRoutineEvent
    }

    @ViewBuilder
    func timeAdornment(
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
        if let recurringParent {
            DayOfWeekSpreadView(
                selected: Set(recurringParent.events.map { $0.dayOfWeek }),
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
