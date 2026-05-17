//
//  DayOfWeekPicker.swift
//  Planner
//
//  Created by Alex Green on 4/6/26.
//

import SwiftUI

// Clean

struct DayOfWeekPickerView: View {
    @Binding var daysOfWeek: Set<Weekday>

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

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
                    .foregroundStyle(
                        daysOfWeek.contains(weekday)
                            ? Color.inverseLabel : Color.label
                    )
                    .font(
                        .system(
                            size: 20,
                            weight: .black,
                            design: .rounded
                        )
                    )
                    .background(
                        daysOfWeek.contains(weekday)
                            ? Circle()
                            .fill(accentColor.color)
                            .frame(width: 36, height: 36)
                            : nil
                    )
                    .contentShape(Circle())
                    .onTapGesture {
                        toggleDay(weekday)
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Functions

    private func toggleDay(_ day: Weekday) {
        if daysOfWeek.contains(day) {
            daysOfWeek.remove(day)
        } else {
            daysOfWeek.insert(day)
        }
    }
}
