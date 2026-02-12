//
//  TransferDestinationIndicator.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftUI

struct TransferDestinationIndicatorView: View {
    let title: String
    let iconConfig: IconConfig

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: iconConfig.name)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundStyle(
                    iconConfig.primaryColor ?? Color.secondary
                )

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(uiColor: .label))
        }
    }
}
