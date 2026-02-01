//
//  NavigationManager.swift
//  Planner
//
//  Created by Alex Green on 1/29/26.
//

import SwiftUI
import Combine

// NOTE: This is deprecated. Keeping around in case auto-open today is re-integrated in future.

@MainActor
class NavigationManager: ObservableObject {
    @Published var wasTodayPlannerAutoOpened = false
}
