//
//  DayOfWeekPicker.swift
//  Planner
//
//  Created by Alex Green on 4/6/26.
//

import SwiftUI

// Clean

struct DayOfWeekPickerView: View {
    @Binding var daysOfWeek: Set<DayOfWeek>

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    var body: some View {
        HStack {
            ForEach(
                Array(DayOfWeek.allCases.enumerated()),
                id: \.element
            ) { index, dayOfWeek in
                if index != 0 {
                    Spacer()
                }

                Text(dayOfWeek.initial)
                    .foregroundStyle(
                        daysOfWeek.contains(dayOfWeek)
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
                        daysOfWeek.contains(dayOfWeek)
                            ? Circle()
                                .fill(accentColor.color)
                                .frame(width: 36, height: 36)
                            : nil
                    )
                    .contentShape(Circle())
                    .onTapGesture {
                        toggleDay(dayOfWeek)
                    }

            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Functions

    private func toggleDay(_ day: DayOfWeek) {
        if daysOfWeek.contains(day) {
            daysOfWeek.remove(day)
        } else {
            daysOfWeek.insert(day)
        }
    }

}
