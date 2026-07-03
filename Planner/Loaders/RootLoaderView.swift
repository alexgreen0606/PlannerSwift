//
//  RootLoaderView.swift
//  Planner
//
//  Created by Alex Green on 6/28/26.
//

import SwiftData
import SwiftUI

struct RootLoaderView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    @Query private var plannerSettingsList: [Settings]

    private var settings: Settings? {
        plannerSettingsList.first
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if let settings {
                RootTabView(
                    modelContext: modelContext,
                    todayService: todayService,
                    plannerCoverStore: plannerCoverStore,
                    ekEventStore: calendarService.ekEventStore,
                    settings: settings
                )
            }
        }
        .task {
            modelContext.ensurePlannerSettings(
                settings: plannerSettingsList
            )
        }
    }
}
