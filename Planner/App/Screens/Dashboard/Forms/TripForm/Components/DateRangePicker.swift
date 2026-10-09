//
//  DateRangePicker.swift
//  Planner
//
//  Created by Alex Green on 3/23/26.
//

import SwiftUI

struct DateRangePickerView: View {
    @Binding var selectedDates: Set<DateComponents>

    @EnvironmentObject private var todayService: TodayService

    private var calendar: Calendar {
        Calendar.current
    }

    // MARK: - Body

    var body: some View {
        MultiDatePicker(
            "Select Date Range",
            selection: Binding(
                get: { selectedDates },
                set: updateSelectedDateComponents
            ),
            in: todayService.multiDatePickerBounds
        )
    }

    // MARK: - Functions

    private func updateSelectedDateComponents(
        _ newDates: Set<DateComponents>
    ) {
        // MARK: Handle Date de-selection.

        // Pre iOS 27 case: Date was de-selected.
        if newDates.count == selectedDates.count {
            // MultiDatePicker does not grant access to which date was removed from the selections.
            // In this case we'll need to just clear the list and have the user start again.
            selectedDates = []
            return
        }

        // iOS 27 case: Date was de-selected.
        if newDates.count < selectedDates.count, #available(iOS 27, *) {
            handleDateDeselection(newDates)
            return
        }

        switch newDates.count {
        case 0, 1:
            selectedDates = newDates
        case 2:
            // MARK: Two dates are selected. Fill all dates between them.

            let (startDate, endDate) = getStartAndEnd(for: newDates)

            updateDateRange(
                from: startDate,
                to: endDate
            )

        default:
            // MARK: New date was selected. Expand the range to fill all dates in-between.

            let (startDate, endDate) = getStartAndEnd(for: selectedDates)

            guard
                let clickedDateComponents = newDates.subtracting(
                    selectedDates
                )
                .first,
                let clickedDate = calendar.date(
                    from: clickedDateComponents
                ),
                let prevEarliestDate = calendar.date(
                    from: startDate
                )
            else {
                return
            }

            if clickedDate < prevEarliestDate {
                updateDateRange(
                    from: clickedDateComponents,
                    to: endDate
                )
            } else {
                updateDateRange(
                    from: startDate,
                    to: clickedDateComponents
                )
            }
        }
    }

    private func handleDateDeselection(_ newDates: Set<DateComponents>) {
        let (startDate, endDate) = getStartAndEnd(for: selectedDates)

        if let clickedDate = selectedDates.subtracting(newDates).first {
            if [startDate, endDate].contains(clickedDate) {
                selectedDates = newDates
                return
            }

            let distanceFromStart = abs(
                calendar.dateComponents(
                    [.day],
                    from: startDate,
                    to: clickedDate
                ).day ?? 0
            )

            let distanceFromEnd = abs(
                calendar.dateComponents(
                    [.day],
                    from: clickedDate,
                    to: endDate
                ).day ?? 0
            )

            if distanceFromStart < distanceFromEnd {
                // Move the start of the range.
                updateDateRange(from: clickedDate, to: endDate)
            } else {
                // Move the end of the range.
                updateDateRange(from: startDate, to: clickedDate)
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

    private func getStartAndEnd(for dates: Set<DateComponents>) -> (
        startDate: DateComponents, endDate: DateComponents
    ) {
        let sortedDates = dates.sorted {
            guard let lhsDate = calendar.date(from: $0),
                let rhsDate = calendar.date(from: $1)
            else {
                return false
            }

            return lhsDate < rhsDate
        }

        let earliest = sortedDates.first!
        let latest = sortedDates.last!

        return (
            startDate: earliest, endDate: latest
        )
    }
}
