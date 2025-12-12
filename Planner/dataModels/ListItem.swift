//
//  ListItem.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData

@available(iOS 26.0, *)
@Model
class ListItem {
    var title: String = ""
    var isChecked: Bool = false
    var sortIndex: Double
    
    init(sortIndex: Double) {
        self.sortIndex = sortIndex
    }
}
