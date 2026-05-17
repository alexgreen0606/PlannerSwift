//
//  DateRangePicker.swift
//  Planner
//
//  Created by Alex Green on 3/23/26.
//

import SwiftUI

// Clean

struct DateRangePickerView: View {
    @Binding var selectedDates: Set<DateComponents>

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
        .oneMonth

    @EnvironmentObject private var TodaystampService: TodaystampService

    private var dateBounds: Range<Date> {
        keepPastEventsDuration.cutoffDate ..< TodaystampService.maxCalendarDate
    }

    var body: some View {
        MultiDatePicker(
            "Select Date Range",
            selection: Binding(
                get: { selectedDates },
                set: updateSelectedDateComponents
            ),
            in: dateBounds
        )
    }

    private func updateSelectedDateComponents(
        _ selections: Set<DateComponents>
    ) {
        let calendar = Calendar.current

        let sortedSelections = selections.sorted { lhs, rhs in
            guard let lhsDate = calendar.date(from: lhs),
                  let rhsDate = calendar.date(from: rhs)
            else {
                return false
            }
            return lhsDate < rhsDate
        }

        let earliest = sortedSelections.first
        let latest = sortedSelections.last

        switch sortedSelections.count {
        case 0, 1:
            selectedDates = selections
        case 2:
            selectedDates = buildRange(from: earliest!, to: latest!)
        default:
            let sortedExisting = selectedDates.sorted { lhs, rhs in
                guard let lhsDate = calendar.date(from: lhs),
                      let rhsDate = calendar.date(from: rhs)
                else {
                    return false
                }
                return lhsDate < rhsDate
            }
            let prevEarliestDateComponents = sortedExisting.first!
            let prevLatestDateComponents = sortedExisting.last!
            let prevEarliestDate = calendar.date(
                from: prevEarliestDateComponents
            )
            let prevLatestDate = calendar.date(from: prevLatestDateComponents)

            var clickedDate: Date?
            var clickedDateComponents: DateComponents

            if selectedDates.count < selections.count {
                guard
                    let added = selections.subtracting(selectedDates)
                    .first
                else {
                    return
                }
                clickedDateComponents = added
                clickedDate = calendar.date(from: added)
            } else {
                // NOTE: MultiDatePicker does not grant access to events that were "removed" from the selections.
                // In this case we'll need to just clear the list and have the user start again.
                selectedDates = []
                return
            }

            guard let clickedDate, let prevLatestDate, let prevEarliestDate
            else {
                return
            }

            let distanceToEarliest = abs(
                clickedDate.timeIntervalSince(prevEarliestDate)
            )
            let distanceToLatest = abs(
                clickedDate.timeIntervalSince(prevLatestDate)
            )

            if distanceToEarliest < distanceToLatest {
                selectedDates = buildRange(
                    from: clickedDateComponents,
                    to: prevLatestDateComponents
                )
            } else {
                selectedDates = buildRange(
                    from: prevEarliestDateComponents,
                    to: clickedDateComponents
                )
            }
        }
    }

    private func buildRange(from start: DateComponents, to end: DateComponents)
        -> Set<DateComponents>
    {
        let calendar = Calendar.current

        guard let startDate = calendar.date(from: start),
              let endDate = calendar.date(from: end)
        else {
            return []
        }

        var expandedDates = Set<DateComponents>()

        var date = startDate
        while date <= endDate {
            expandedDates.insert(
                calendar.dateComponents([.year, .month, .day], from: date)
            )
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        return expandedDates
    }
}
