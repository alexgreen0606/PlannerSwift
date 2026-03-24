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

struct PlannerBuilderView: View {
    private let datestamp: String
    private let settings: PlannerSettings
    private let previewType: PlannerPreviewType?
    private let plannerSearchQuery: PlannerSearchQuery?
    private let customTitle: String?
    private let namespace: Namespace.ID?
    private let transitionSource: String?

    init(
        datestamp: String,
        settings: PlannerSettings,
        previewType: PlannerPreviewType? = nil,
        plannerSearchQuery: PlannerSearchQuery? = nil,
        customTitle: String? = nil,
        namespace: Namespace.ID? = nil,
        transitionSource: String? = nil
    ) {
        self.datestamp = datestamp
        self.previewType = previewType
        self.plannerSearchQuery = plannerSearchQuery
        self.customTitle = customTitle
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

    @StateObject private var notificationManager = NotificationManager()

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
                    customTitle: customTitle,
                    namespace: namespace,
                    transitionSource: transitionSource
                )
                .overlay {
                    NotificationsView()
                }
                .environmentObject(notificationManager)
            }
        }
        .task {
            modelContext.ensurePlanner(planners: planners, datestamp: datestamp)
        }
    }
}
