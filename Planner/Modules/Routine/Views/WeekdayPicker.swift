//
//  WeekdayPicker.swift
//  Planner
//
//  Created by Alex Green on 4/6/26.
//

import SwiftUI

struct WeekdayPickerView: View {
    @Binding var selectedWeekdays: Set<Weekday>

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        HStack {
            ForEach(
                Array(Weekday.allCases.enumerated()),
                id: \.element
            ) { index, weekday in
                if index != 0 {
                    Spacer()
                }

                Text(weekday.initial)
                    .font(
                        .system(
                            size: 20,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        selectedWeekdays.contains(weekday)
                            ? Color.inverseLabel : Color.label
                    )
                    .background(
                        selectedWeekdays.contains(weekday)
                            ? selectionIndicator : nil
                    )
                    .contentShape(Circle())
                    .onTapGesture {
                        toggleWeekday(weekday)
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - View Builders

    private var selectionIndicator: some View {
        Circle()
            .fill(accentColor.swiftUiColor)
            .frame(width: 36, height: 36)
    }

    // MARK: - Functions

    private func toggleWeekday(_ weekday: Weekday) {
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
    }
}
