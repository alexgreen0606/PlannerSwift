//
//  PlannerBuilder.swift
//  Planner
//
//  Created by Alex Green on 2/15/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct PlannerBuilderView: View {
    private let datestamp: String
    private let settings: PlannerSettings
    private let previewType: PlannerPreviewType?
    private let namespace: Namespace.ID?
    
    init(
        datestamp: String,
        settings: PlannerSettings,
        previewType: PlannerPreviewType? = nil,
        namespace: Namespace.ID? = nil
    ) {
        self.datestamp = datestamp
        self.previewType = previewType
        self.settings = settings
        self.namespace = namespace

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
                    namespace: namespace
                )
            }
        }
        .task {
            modelContext.ensurePlanner(planners: planners, datestamp: datestamp)
        }
    }
}
