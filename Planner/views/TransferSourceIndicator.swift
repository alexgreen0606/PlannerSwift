//
//  TransferSourceIndicator.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftUI

// Clean

struct TransferSourceIndicatorView: View {
    let title: String
    let subtitle: String
    let iconConfig: IconConfig

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.label)

            HStack(spacing: 4) {
                Image(systemName: iconConfig.name)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(
                        iconConfig.primaryColor
                    )

                Text(subtitle)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(
                        Color.secondary
                    )
            }
        }
    }
}
