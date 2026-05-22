//
//  TransferSourceIndicator.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftUI

struct TransferSourceIndicatorView: View {
    let title: String
    let subtitle: LocalizedStringKey
    let iconConfig: IconConfig?
    
    init(title: String, subtitle: LocalizedStringKey, iconConfig: IconConfig? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.iconConfig = iconConfig
    }

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
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

            Text(subtitle)
                .font(.system(size: 12))
                .foregroundStyle(Color.secondary)
        }
    }
}
