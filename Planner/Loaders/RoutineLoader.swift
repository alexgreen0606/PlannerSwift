//
//  RoutineLoader.swift
//  Planner
//
//  Created by Alex Green on 6/19/26.
//

import SwiftData
import SwiftUI

struct RoutineLoaderView<Content: View>: View {
    private let weekday: Weekday
    private let content: (Routine) -> Content

    init(
        weekday: Weekday,
        @ViewBuilder content: @escaping (Routine) -> Content
    ) {
        self.weekday = weekday
        self.content = content

        _routines = Query(
            filter: Routine.routines(for: weekday)
        )
    }

    @Query private var routines: [Routine]

    private var routine: Routine? {
        routines.first
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if let routine {
                content(routine)
            }
        }
        .task {
            // TODO: add an ensure. Maybe at app root?
            // modelContext.ensurePlanner(planners: planners, datestamp: datestamp)
        }
    }
}
