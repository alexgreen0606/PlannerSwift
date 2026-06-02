//
//  TransferSelectionIndicator.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftUI

struct LabelValueView: View {
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
        HStack {
            if let iconConfig {
                Image(systemName: iconConfig.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        iconConfig.primaryColor,
                        iconConfig.secondaryColor
                    )
            }

            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.label)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 10, weight: .regular, design: .default))
                        .foregroundStyle(
                            Color.secondary
                        )
                }
            }
        }
//        .animateLazyAction(from: value)
//        VStack(spacing: 2) {
//            HStack(spacing: 6) {
//                if let iconConfig {
//                    Image(systemName: iconConfig.name)
//                        .foregroundStyle(
//                            iconConfig.primaryColor,
//                            iconConfig.secondaryColor
//                        )
//                }
//
//                Text(title)
//                    .foregroundStyle(Color.label)
//            }
//            .font(.system(size: 14, weight: .bold, design: .rounded))
//
//            if let subtitle {
//                Text(subtitle)
//                    .font(.system(size: 10))
//                    .foregroundStyle(Color.secondary)
//            }
//        }
    }
}
