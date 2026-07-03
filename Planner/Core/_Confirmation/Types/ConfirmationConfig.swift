//
//  ConfirmationConfig.swift
//  Planner
//
//  Created by Alex Green on 5/23/26.
//

import Foundation

struct ConfirmationConfig {
    let id = UUID()
    let title: String
    let message: String
    let actions: [ConfirmationAction]
}
