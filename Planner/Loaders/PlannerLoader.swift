//
//  PlannerLoader.swift
//  Planner
//
//  Created by Alex Green on 5/17/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct PlannerLoaderView<Content: View>: View {
    private let datestamp: String
    private let settings: PlannerSettings
    private let content: (PlannerContext, PlannerEventContext) -> Content

    init(
        datestamp: String,
        settings: PlannerSettings,
        @ViewBuilder content:
        @escaping (PlannerContext, PlannerEventContext) -> Content
    ) {
        self.datestamp = datestamp
        self.settings = settings
        self.content = content

        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == datestamp
            }
        )
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var plannerSyncService: PlannerSyncService

    @Query private var planners: [Planner]

    @StateObject private var plannerManager = ListEngine<PlannerEvent>()

    private var planner: Planner? {
        planners.first
    }

    private var plannerDay: DateInRegion? {
        guard let planner else {
            return nil
        }
        return datestamp.startOfDay(in: planner.region(settings: settings))
    }

    private var plannerLocation: Location? {
        guard let planner else {
            return nil
        }
        return planner.location(
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )
    }

    var body: some View {
        ZStack {
            if let planner, let plannerDay {
                PlannerEventContextLoaderView(
                    plannerContext: PlannerContext(
                        planner: planner,
                        plannerDay: plannerDay,
                        plannerLocation: plannerLocation
                    ),
                    plannerSyncService: plannerSyncService,
                    settings: settings
                ) { plannerContext, eventContext in
                    content(plannerContext, eventContext)
                }
                .environmentObject(plannerManager)
            }
        }
        .task {
            modelContext.ensurePlanner(planners: planners, datestamp: datestamp)
        }
    }
}
