//
//  TransferSourceIndicator.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftUI

struct TransferSourceIndicatorView: View {
    let title: String
    let subtitle: String
    let iconConfig: IconConfig

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color(uiColor: .label))

            HStack(spacing: 4) {
                Image(systemName: iconConfig.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(
                        iconConfig.primaryColor ?? Color.secondary
                    )

                Text(subtitle)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(
                        Color(uiColor: .secondaryLabel)
                    )
            }
        }
    }
}
