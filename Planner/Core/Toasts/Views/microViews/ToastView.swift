//
//  ToastView.swift
//  Planner
//
//  Created by Alex Green on 3/18/26.
//

import SwiftUI

struct ToastView<ListItemType: ListItem>: View {
    let config: Toast
    let listStore: ListStore<ListItemType>?

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    var body: some View {
        HStack {
            Image(systemName: config.iconConfig.name)
                .foregroundStyle(
                    config.iconConfig.primaryColor,
                    config.iconConfig.secondaryColor
                )

            VStack(alignment: .leading) {
                Text(config.title)
                    .font(.system(size: 16))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                if let customSubtitle = config.customSubtitle {
                    customSubtitle
                } else if let subtitle = config.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .lineLimit(1)
                        .foregroundStyle(Color.secondary)
                }
            }

            Spacer()

            if let action = config.action {
                ActionButtonView(
                    label: "View",
                    systemImage: "chevron.right",
                    spacing: 0,
                    endAdornment: true,
                    onTap: {
                        action()
                        listStore?.focusedId = nil
                    }
                )
            }
        }
        .padding(.horizontal)
        .frame(height: 50)
        .clipShape(.capsule)
        .contentShape(.capsule)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal)
        .padding(.trailing, config.variant.trailingPadding)
        .offset(y: -config.variant.verticalOffset)
        .transition(
            .offset(y: config.variant.verticalOffset + 30).combined(
                with: .opacity
            )
        )
        .ignoresSafeArea()
    }
}
