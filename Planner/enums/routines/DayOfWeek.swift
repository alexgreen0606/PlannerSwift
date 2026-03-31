//
//  DayOfWeek.swift
//  Planner
//
//  Created by Alex Green on 3/30/26.
//

import SwiftUI

// Clean

enum DayOfWeek: String, Codable, CaseIterable {
    case sunday
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    
    var initial: String {
        String(self.rawValue.prefix(1)).uppercased()
    }
    
}
