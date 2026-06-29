//
//  ModelContextLoaderView.swift
//  Planner
//
//  Created by Alex Green on 6/28/26.
//

import SwiftData
import SwiftUI

struct ModelContextLoaderView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarService: CalendarService
    
    @Query private var plannerSettingsList: [PlannerSettings]

    private var settings: PlannerSettings? {
        plannerSettingsList.first
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if let settings {
                RootTabView(
                    modelContext: modelContext,
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
