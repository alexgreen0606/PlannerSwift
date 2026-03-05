//
//  ConfirmationAction.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftUI

// Clean

struct ConfirmationAction<Item> {
    let title: String
    let role: ButtonRole?
    let handler: (Item) -> Void
}
