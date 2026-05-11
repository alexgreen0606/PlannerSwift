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
    let iconConfig: IconConfig

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconConfig.name)
                .imageScale(.medium)
                .foregroundStyle(
                    iconConfig.primaryColor
                )

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.label)
        }
    }
}
