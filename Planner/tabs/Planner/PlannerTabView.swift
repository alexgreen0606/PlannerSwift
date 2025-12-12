//
//  PlannerTabView.swift
//  Planner
//
//  Created by Alex Green on 12/8/25.
//

import SwiftDate
import SwiftUI

struct PlannerTabView: View {
    @EnvironmentObject var todaystampManager: TodaystampManager
    
    let plannerManager = ListManager()

    @State private var isCalendarPickerOpen = false
    @State var navigationManager = NavigationManager.shared

    var body: some View {
        NavigationStack(path: $navigationManager.plannerPath) {
            PlannerView(datestamp: todaystampManager.todaystamp)
                .navigationDestination(for: String.self) { datestamp in
                    PlannerView(datestamp: datestamp)
                        .navigationBarBackButtonHidden(true)
                }
        }
        .environmentObject(plannerManager)
    }
}

#Preview {
    PlannerTabView()
}
