//
//  RoutineContextLoader.swift
//  Planner
//
//  Created by Alex Green on 6/19/26.
//

import SwiftUI

struct RoutineContextLoaderView<Content: View>: View {
    let weekday: Weekday
    let content: (RoutineContext) -> Content

    // MARK: - Body

    var body: some View {
        RoutineLoaderView(weekday: weekday) { routine in
            RoutineEventContextsLoaderView(
                routine: routine
            ) { sortedRoutineEventContexts in
                content(
                    RoutineContext(
                        routine: routine,
                        sortedRoutineEventContexts: sortedRoutineEventContexts
                    )
                )
            }
        }
    }
}
