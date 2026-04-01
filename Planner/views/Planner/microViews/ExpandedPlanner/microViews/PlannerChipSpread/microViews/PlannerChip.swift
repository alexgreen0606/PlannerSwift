//
//  PlannerChip.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import Contacts
import SwiftUI

// Clean

struct PlannerChipView: View {
    let title: String
    let iconConfig: IconConfig?
    let color: Color?
    let onTap: (() -> Void)?

    var body: some View {
        EventView(title: title, iconConfig: iconConfig, color: color)
            .glassChip(color: color, onTap: onTap)
    }
}
