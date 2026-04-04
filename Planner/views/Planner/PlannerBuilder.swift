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
    private let header: Header
    private let namespace: Namespace.ID?
    private let transitionSource: String?

    init(
        datestamp: String,
        settings: PlannerSettings,
        previewType: PlannerPreviewType? = nil,
        plannerSearchQuery: PlannerSearchQuery? = nil,
        header: Header,
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
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher

    @Query private var planners: [Planner]

    private var planner: Planner? {
        planners.first
    }

    var body: some View {
        let content = ZStack {
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

        if let previewType {
            if previewType != .search {
                content
                    .padding(.top)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
                    .frame(
                        width: todaystampWatcher.todaystamp == datestamp
                            && previewType != .trip ? 350 : 240
                    )
                    .frame(
                        height: PlannerLayout.PREVIEW_CARD_HEIGHT,
                        alignment: .top
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.cardBackground)
                    )
                
            } else {
                content.frame(maxWidth: .infinity)
                
            }
        } else {
            content
            
        }
    }
}
