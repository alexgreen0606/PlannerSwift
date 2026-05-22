//
//  TransferDestinationIndicator.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftUI

// Clean

struct TransferDestinationIndicatorView: View {
    let title: String
    let iconConfig: IconConfig?
    
    init(title: String, iconConfig: IconConfig? = nil) {
        self.title = title
        self.iconConfig = iconConfig
    }

    var body: some View {
        HStack(spacing: 6) {
            if let iconConfig {
                Image(systemName: iconConfig.name)
                    .foregroundStyle(
                        iconConfig.primaryColor,
                        iconConfig.secondaryColor
                    )
            }

            Text(title)
                .foregroundStyle(Color.label)
        }
        .font(.system(size: 14, weight: .bold, design: .rounded))
    }
}
