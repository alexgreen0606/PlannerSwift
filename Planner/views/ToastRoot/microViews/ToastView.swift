//
//  Toast.swift
//  Planner
//
//  Created by Alex Green on 3/18/26.
//

import SwiftUI

struct ToastView: View {
    let config: Toast

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: config.iconConfig.name)
                .foregroundStyle(
                    config.iconConfig.primaryColor,
                    config.iconConfig.secondaryColor
                )

            Text(config.title)
                .font(.body)
                .lineLimit(1)
                .layoutPriority(1)

            Spacer()

            if let actionText = config.actionText, let action = config.action {
                ActionButtonView(
                    label: actionText,
                    systemImage: "chevron.right",
                    spacing: 0,
                    endAdornment: true,
                    onTap: action
                )
            }
        }
        .padding(.horizontal)
        .frame(height: 50)
        .clipShape(.capsule)
        .contentShape(.capsule)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal)
        .padding(.trailing, config.variant.trailingPadding + 16)
        .offset(y: -config.variant.verticalOffset)
        .transition(
            .offset(y: config.variant.verticalOffset + 30).combined(
                with: .opacity
            )
        )
        .ignoresSafeArea()
    }
}
