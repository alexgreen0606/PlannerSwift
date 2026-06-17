//
//  ListItem.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import Foundation

extension ListItem {
    var transitionId: String {
        stableId.uuidString
    }
}
