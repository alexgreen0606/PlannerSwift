//
//  NavigationManager.swift
//  Planner
//
//  Created by Alex Green on 1/29/26.
//

import SwiftUI
import Combine

@MainActor
class NavigationManager: ObservableObject {
    @Published var wasTodayPlannerAutoOpened = false
}
