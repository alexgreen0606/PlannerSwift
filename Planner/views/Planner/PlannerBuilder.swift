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
    private let namespace: Namespace.ID?

    init(
        datestamp: String,
        settings: PlannerSettings,
        previewType: PlannerPreviewType? = nil,
        plannerSearchQuery: PlannerSearchQuery? = nil,
        namespace: Namespace.ID? = nil
    ) {
        self.datestamp = datestamp
        self.previewType = previewType
        self.plannerSearchQuery = plannerSearchQuery
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
                    namespace: namespace
                )
                .environmentObject(notificationManager)
                .overlay {
                    VStack {
                        ForEach(notificationManager.notifications, id: \.id) {
                            config in
                            NotificationView(config: config)
                        }
                        Spacer()
                    }
                    .animation(
                        .linear,
                        value: notificationManager.notifications
                    )
                }
            }
        }
        .task {
            modelContext.ensurePlanner(planners: planners, datestamp: datestamp)
        }
    }
}
