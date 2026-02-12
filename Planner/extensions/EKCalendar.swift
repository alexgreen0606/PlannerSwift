//
//  EKCalendar.swift
//  Planner
//
//  Created by Alex Green on 12/21/25.
//

import EventKit
import SwiftUI

extension EKCalendar {
    
    var iconName: String {
        let title = self.title.lowercased()

        if title.contains("birthday") {
            return "birthday.cake.fill"
        }

        if title.contains("holiday") {
            return "globe.americas.fill"
        }

        return "calendar"
    }
    
    var color: Color {
        Color(cgColor: self.cgColor)
    }
    
}
