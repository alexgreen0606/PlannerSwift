//
//  PlannerLoader.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct PlannerLoaderView<Content: View>: View {
    private let datestamp: String
    private let content: (Planner) -> Content

    init(
        datestamp: String,
        @ViewBuilder content: @escaping (Planner) -> Content
    ) {
        self.datestamp = datestamp
        self.content = content

        _planners = Query(
            filter: Planner.planners(datestamp: datestamp)
        )
    }

    @Environment(\.modelContext) private var modelContext

    @Query private var planners: [Planner]

    private var planner: Planner? {
        planners.first
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if let planner {
                content(planner)
            }
        }
    }
}
