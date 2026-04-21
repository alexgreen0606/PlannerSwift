//
//  ListItem.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

// Clean

@available(iOS 26.0, *)
@Model
class ListItem {
    
    var stableId = UUID()
    
    var title: String = ""
    var isCompleted: Bool = false
    var sortIndex: Double = 10.0
    
    init(sortIndex: Double) {
        self.sortIndex = sortIndex
    }
}
