//
//  TransferSelectionIndicator.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftUI

struct TransferSelectionIndicatorView: View {
    private let title: String
    private let subtitle: LocalizedStringKey?
    private let iconConfig: IconConfig?

    init(
        title: String,
        subtitle: LocalizedStringKey? = nil,
        iconConfig: IconConfig? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.iconConfig = iconConfig
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 2) {
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

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondary)
            }
        }
    }
}
