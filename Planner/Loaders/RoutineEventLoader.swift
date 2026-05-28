//
//  RoutineEventLoader.swift
//  Planner
//
//  Created by Alex Green on 5/19/26.
//

import SwiftData
import SwiftUI

struct RoutineEventLoaderView<Content: View>: View {
    private let weekday: Weekday
    private let content: ([RoutineEvent]) -> Content

    init(
        weekday: Weekday,
        @ViewBuilder content: @escaping ([RoutineEvent]) -> Content
    ) {
        self.weekday = weekday
        self.content = content

        let weekdayRawValue = weekday.rawValue

        _weekdayInstances = Query(
            filter: #Predicate<RoutineEventWeekdayInstance> {
                $0.weekdayRawValue == weekdayRawValue
            },
            sort: \.sortDate
        )
    }

    @Query private var weekdayInstances: [RoutineEventWeekdayInstance]

    // MARK: - Body

    var body: some View {
        content(weekdayInstances.compactMap(\.routineEvent))
    }
}
