//
//  ToastView.swift
//  Planner
//
//  Created by Alex Green on 3/18/26.
//

import SwiftUI

struct ToastView<Item: ListItem>: View {
    let toast: Toast
    let listEngine: ListEngine<Item>?

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.iconConfig.name)
                .foregroundStyle(
                    toast.iconConfig.primaryColor,
                    toast.iconConfig.secondaryColor
                )

            VStack(alignment: .leading) {
                Text(toast.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.label)

                if let customSubtitle = toast.customSubtitle {
                    customSubtitle
                } else if let subtitle = toast.subtitle {
                    Text(subtitle)
                        .lineLimit(1)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let action = toast.action {
                ActionButtonView(
                    label: "View",
                    systemImage: "chevron.right",
                    endAdornment: true,
                    spacing: 0,
                    onTap: {
                        action()
                        listEngine?.focusedId = nil
                    }
                )
            }
        }
        .frame(height: 50)
        .clipShape(.capsule)
        .contentShape(.capsule)
        .padding(.horizontal)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal)
        .offset(y: -toast.variant.verticalOffset)
        .transition(
            .offset(y: toast.variant.verticalOffset).combined(
                with: .opacity
            )
        )
        .ignoresSafeArea()
    }
}
