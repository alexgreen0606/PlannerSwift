//
//  KeepCanceledEventsDuration.swift
//  Planner
//
//  Created by Alex Green on 1/23/26.
//

import SwiftDate
import SwiftUI

// Clean

enum KeepCanceledEventsDuration: String, Codable, CaseIterable {
    case startOfDay
    case forever

    static var title: String {
        "Keep Canceled Events"
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
