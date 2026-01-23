//
//  KeepCanceledPlansDuration.swift
//  Planner
//
//  Created by Alex Green on 1/23/26.
//

import SwiftDate
import SwiftUI

enum KeepCanceledPlansDuration: String, Codable, CaseIterable {
    case startOfDay
    case forever
    
    var title: String {
        "Keep Canceled Plans"
    }

    var label: String {
        switch self {
        case .startOfDay:
            return "Until Start Of Day"
        case .forever:
            return "Forever"
        }
    }
    
}
