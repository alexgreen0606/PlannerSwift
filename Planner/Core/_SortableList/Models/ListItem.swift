//
//  ListItem.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

@available(iOS 26.0, *)
@Model
class ListItem {
    var stableId = UUID()
    
    var title: String = ""
    var isCompleted: Bool = false
    
    init() {}
}
