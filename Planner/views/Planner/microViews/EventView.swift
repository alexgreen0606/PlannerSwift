//
//  EventView.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import Contacts
import EventKit
import SwiftUI

// Clean

struct EventView: View {
    let title: String
    let iconConfig: IconConfig?
    let color: Color?

    var body: some View {
        HStack(spacing: 6) {
            if let iconConfig {
                Image(systemName: iconConfig.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .foregroundStyle(
                        iconConfig.primaryColor,
                        iconConfig.secondaryColor
                    )
            }

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color ?? Color.label)
        }
    }
}
