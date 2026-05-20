//
//  DateRangePicker.swift
//  Planner
//
//  Created by Alex Green on 3/23/26.
//

import SwiftUI

struct DateRangePickerView: View {
    @Binding var selectedDates: Set<DateComponents>

    @EnvironmentObject private var todaystampService: TodaystampService

    // MARK: - Body

    var body: some View {
        MultiDatePicker(
            "Select Date Range",
            selection: Binding(
                get: { selectedDates },
                set: updateSelectedDateComponents
            ),
            in: todaystampService.multiDatePickerBounds
        )
    }

    // MARK: - Functions

    private func updateSelectedDateComponents(
        _ newDates: Set<DateComponents>
    ) {
        if newDates.count == selectedDates.count {
            // MARK: Date was de-selected. Clear the entire selection.
            // Limitation: MultiDatePicker does not grant access to which date was "removed" from the selections.
            // In this case we'll need to just clear the list and have the user start again.
            selectedDates = []
            return
        }

        let calendar = Calendar.current

        switch newDates.count {
        case 0, 1:
            selectedDates = newDates
        case 2:
            // MARK: Two dates are selected. Fill all dates between them.

            let sortedNewDates = newDates.sorted {
                guard let lhsDate = calendar.date(from: $0),
                    let rhsDate = calendar.date(from: $1)
                else {
                    return false
                }

                return lhsDate < rhsDate
            }

            updateDateRange(
                from: sortedNewDates.first!,
                to: sortedNewDates.last!
            )
        default:
            // MARK: New date was selected. Expand the range to fill all dates in-between.

            let sortedPrevDates = selectedDates.sorted {
                guard let lhsDate = calendar.date(from: $0),
                    let rhsDate = calendar.date(from: $1)
                else {
                    return false
                }

                return lhsDate < rhsDate
            }
            let prevEarliest = sortedPrevDates.first!
            let prevLatest = sortedPrevDates.last!

            guard
                let clickedDateComponents = newDates.subtracting(selectedDates)
                    .first,
                let clickedDate = calendar.date(from: clickedDateComponents),
                let prevEarliestDate = calendar.date(
                    from: prevEarliest
                )
            else {
                return
            }

            if clickedDate < prevEarliestDate {
                updateDateRange(
                    from: clickedDateComponents,
                    to: prevLatest
                )
            } else {
                updateDateRange(
                    from: prevEarliest,
                    to: clickedDateComponents
                )
            }
        }
    }

    private func updateDateRange(
        from start: DateComponents,
        to end: DateComponents
    ) {
        let calendar = Calendar.current

        guard let startDate = calendar.date(from: start),
            let endDate = calendar.date(from: end)
        else {
            return
        }

        var expandedDates = Set<DateComponents>()

        var date = startDate
        while date <= endDate {
            expandedDates.insert(
                calendar.dateComponents([.year, .month, .day], from: date)
            )
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        selectedDates = expandedDates
    }
}
