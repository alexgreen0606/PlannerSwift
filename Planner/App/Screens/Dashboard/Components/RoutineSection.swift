//
//  RoutineSection.swift
//  Planner
//
//  Created by Alex Green on 3/30/26.
//

import SwiftData
import SwiftUI

struct RoutineSectionView: View {
    @Binding var routineCoverContext: Weekday?
    let namespace: Namespace.ID

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var todayService: TodayService

    @Query private var routineEvents: [RoutineEvent]

    // MARK: - Body

    var body: some View {
        Section("Routines") {
            HStack {
                ForEach(
                    Array(Weekday.allCases.enumerated()),
                    id: \.element
                ) { index, weekday in
                    if index != 0 {
                        Spacer()
                    }

                    routinePreview(for: weekday)
                        .matchedTransitionSource(id: weekday, in: namespace)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            routineCoverContext = weekday
                        }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .discreetListItem()
    }

    // MARK: - View Builders

    @ViewBuilder
    private func routinePreview(for weekday: Weekday) -> some View {
        let eventCount = routineEvents.count {
            $0.routine?.weekdayRawValue == weekday.rawValue
        }

        VStack(spacing: 0) {
            Text(weekday.initial)
                .font(
                    .system(
                        size: 20,
                        weight: .black,
                        design: .rounded
                    )
                )
                .foregroundStyle(Color.label)

            Capsule()
                .fill(accentColor.color)
                .opacity(
                    todayService.todaystamp.weekday
                        == weekday.label ? 1 : 0
                )
                .frame(width: 18, height: 2)

            Text(eventCount > 0 ? "\(eventCount)" : "")
                .font(.footnote)
                .foregroundStyle(Color.secondary)
                .padding(.top, 2)
        }
    }
}
