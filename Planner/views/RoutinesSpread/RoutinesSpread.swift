//
//  RoutinesSpread.swift
//  Planner
//
//  Created by Alex Green on 3/30/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct RoutineCoverContext: Identifiable {
    var weekday: Weekday

    var id: String {
        weekday.rawValue
    }
}

struct RoutinesSpreadView: View {
    @Binding var routineCoverContext: RoutineCoverContext?

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher

    @Query private var routineEvents: [RoutineEvent]

    @Namespace private var namespace

    var body: some View {
        HStack {
            ForEach(
                Array(Weekday.allCases.enumerated()),
                id: \.element
            ) { index, weekday in
                if index != 0 {
                    Spacer()
                }

                VStack {
                    Text(weekday.initial)
                        .foregroundStyle(
                            Color.label
                        )
                        .font(
                            .system(
                                size: 20,
                                weight: .black,
                                design: .rounded
                            )
                        )

                    let eventCount = weekday.sortedEvents(in: routineEvents)
                        .count
                    Text(eventCount > 0 ? "\(eventCount)" : "")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
                .matchedTransitionSource(id: weekday, in: namespace)
                .contentShape(Rectangle())
                .onTapGesture {
                    routineCoverContext = RoutineCoverContext(
                        weekday: weekday
                    )
                }

            }
        }
        .frame(maxWidth: .infinity)

        // MARK: Routine Cover
        .fullScreenCover(item: $routineCoverContext) { context in
            RoutineView(
                routineCoverContext: $routineCoverContext,
                weekday: context.weekday,
                sortedRoutineEvents: context.weekday.sortedEvents(
                    in: routineEvents
                )
            )
            .id(context.weekday)
            .navigationTransition(
                .zoom(
                    sourceID: context.weekday,
                    in: namespace
                )
            )
        }
    }

}
