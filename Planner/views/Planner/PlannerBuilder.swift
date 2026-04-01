//
//  PlannerBuilder.swift
//  Planner
//
//  Created by Alex Green on 2/15/26.
//

import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct PlannerBuilderView<Header: View>: View {
    private let datestamp: String
    private let settings: PlannerSettings
    private let previewType: PlannerPreviewType?
    private let plannerSearchQuery: PlannerSearchQuery?
    private let header: (DateInRegion) -> Header
    private let namespace: Namespace.ID?
    private let transitionSource: String?

    init(
        datestamp: String,
        settings: PlannerSettings,
        previewType: PlannerPreviewType? = nil,
        plannerSearchQuery: PlannerSearchQuery? = nil,
        header: @escaping (DateInRegion) -> Header,
        namespace: Namespace.ID? = nil,
        transitionSource: String? = nil
    ) {
        self.datestamp = datestamp
        self.previewType = previewType
        self.plannerSearchQuery = plannerSearchQuery
        self.header = header
        self.settings = settings
        self.namespace = namespace
        self.transitionSource = transitionSource

        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == datestamp
            }
        )
    }

    @Environment(\.modelContext) private var modelContext

    @Query private var planners: [Planner]

    private var planner: Planner? {
        planners.first
    }

    var body: some View {
        ZStack {
            if let planner {
                PlannerEventBuilderView(
                    planner: planner,
                    settings: settings,
                    previewType: previewType,
                    plannerSearchQuery: plannerSearchQuery,
                    header: header,
                    namespace: namespace,
                    transitionSource: transitionSource
                )
            }
        }
        .task {
            modelContext.ensurePlanner(planners: planners, datestamp: datestamp)
        }
    }
}
