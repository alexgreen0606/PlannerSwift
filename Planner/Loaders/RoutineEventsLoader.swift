//
//  RoutineEventsLoaderView.swift
//  Planner
//
//  Created by Alex Green on 5/19/26.
//

import SwiftData
import SwiftUI

struct RoutineEventsLoaderView<Content: View>: View {
    private let routine: Routine
    private let content: ([RoutineEvent]) -> Content

    init(
        routine: Routine,
        @ViewBuilder content: @escaping ([RoutineEvent]) -> Content
    ) {
        self.routine = routine
        self.content = content

        _routineEvents = Query(
            filter: RoutineEvent.routineEvents(for: routine),
            sort: \.sortDate
        )
    }

    @Query private var routineEvents: [RoutineEvent]

    // MARK: - Body

    var body: some View {
        content(routineEvents)
    }
}
