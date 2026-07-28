//
//  DataLoader.swift
//  Planner
//
//  Created by Alex Green on 6/28/26.
//

import SwiftData
import SwiftUI

struct DataLoaderView: View {

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    @Query private var plannerSettingsList: [Settings]

    @State private var areRoutinesSafe: Bool = false

    private var settings: Settings? {
        plannerSettingsList.first
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if let settings, areRoutinesSafe {
                EnvironmentLoaderView(
                    plannerCoverStore: plannerCoverStore,
                    modelContext: modelContext,
                    settings: settings
                )
            }
        }
        .task {
            modelContext.ensureSettings(
                settings: plannerSettingsList
            )

            modelContext.ensureRoutines()
            areRoutinesSafe = true
        }
    }
}
