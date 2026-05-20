//
//  RoutineEvent+.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftDate
import SwiftUI

extension RoutineEvent {
    var safePlannerEvents: [PlannerEvent] {
        plannerEvents ?? []
    }

    var safeVariants: [RoutineEventVariant] {
        variants ?? []
    }

    var safeWeekdayInstances: [RoutineEventWeekdayInstance] {
        weekdayInstances ?? []
    }

    var weekdays: Set<Weekday> {
        Set(
            safeWeekdayInstances.compactMap {
                Weekday(rawValue: $0.weekdayRawValue)
            }
        )
    }

    func instance(on weekday: Weekday) -> RoutineEventWeekdayInstance? {
        safeWeekdayInstances.first(where: {
            $0.weekdayRawValue == weekday.rawValue
        })
    }

    func syncWithDraftRoutineEvent(
        _ draft: DraftRoutineEvent
    ) {
        title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        time = draft.hasTime ? draft.date : nil
    }

    func date(in plannerDay: DateInRegion) -> Date? {
        guard let time = time else {
            return nil
        }

        let utcTime = DateInRegion(time, region: .UTC)

        let combined = DateInRegion(
            year: plannerDay.year,
            month: plannerDay.month,
            day: plannerDay.day,
            hour: utcTime.hour,
            minute: utcTime.minute,
            second: 0,
            region: plannerDay.region
        )

        return combined.date
    }

    // MARK: - View Builders

    @ViewBuilder
    func timeAdornment(
        accentColor: AccentColor,
        openEventSheet: (() -> Void)?
    ) -> some View {
        if let time = time {
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
        if weekdays.count > 1 {
            WeekdaySpreadView(
                selected: Set(weekdays),
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
