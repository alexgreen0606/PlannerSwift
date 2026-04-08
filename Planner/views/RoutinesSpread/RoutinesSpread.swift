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
    var dayOfWeek: DayOfWeek

    var id: String {
        dayOfWeek.rawValue
    }

}

struct RoutinesSpreadView: View {

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher

    @Query private var routineEvents: [RoutineEvent]

    @State private var routineCoverContext: RoutineCoverContext? = nil

    @Namespace private var namespace

    var body: some View {
        HStack {
            ForEach(
                Array(DayOfWeek.allCases.enumerated()),
                id: \.element
            ) { index, dayOfWeek in
                if index != 0 {
                    Spacer()
                }

                VStack {
                    Text(dayOfWeek.initial)
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

                    let eventCount = getRoutineEvents(for: dayOfWeek).count
                    Text(eventCount > 0 ? "\(eventCount)" : "")
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
                .matchedTransitionSource(id: dayOfWeek, in: namespace)
                .contentShape(Rectangle())
                .onTapGesture {
                    routineCoverContext = RoutineCoverContext(
                        dayOfWeek: dayOfWeek
                    )
                }

            }
        }
        .frame(maxWidth: .infinity)

        // Day Routines Sheet
        .fullScreenCover(item: $routineCoverContext) { context in
            RoutineView(
                dayOfWeek: context.dayOfWeek,
                sortedRoutineEvents: getRoutineEvents(for: context.dayOfWeek)
            )
            .navigationTransition(
                .zoom(
                    sourceID: context.dayOfWeek,
                    in: namespace
                )
            )
        }
    }

    // MARK: - Functions

    private func getRoutineEvents(for dayOfWeek: DayOfWeek) -> [RoutineEvent] {
        routineEvents.filter { $0.dayOfWeek == dayOfWeek }.sorted {
            $0.sortDate < $1.sortDate
        }
    }
}
