//
//  Separator.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftUI

struct SeparatorView: View {
    private let showLowerDivider: Bool
    private let showUpperDivider: Bool
    private let opacity: Double
    private let settings: Settings
    private let onTap: () -> Void

    init(
        showLowerDivider: Bool = false,
        showUpperDivider: Bool = false,
        opacity: Double = 1,
        settings: Settings,
        onTap: @escaping () -> Void
    ) {
        self.showLowerDivider = showLowerDivider
        self.showUpperDivider = showUpperDivider
        self.opacity = opacity
        self.settings = settings
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: ListLayout.SEPARATOR_HEIGHT)
            .overlay(
                divider
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
    }

    // MARK: - View Builders

    @ViewBuilder
    private var divider: some View {
        if settings.showListDividers {
            VStack {
                if showLowerDivider {
                    Spacer()
                    Divider().background(.tertiary)
                        .opacity(opacity)
                } else if showUpperDivider {
                    Divider().background(.tertiary)
                        .opacity(opacity)
                    Spacer()
                }
            }
        }
    }
}
