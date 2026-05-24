//
//  Separator.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftUI

// Clean

struct SeparatorView: View {
    private let showLowerDivider: Bool
    private let showUpperDivider: Bool
    private let opacity: Double
    private let onTap: () -> Void

    init(
        showLowerDivider: Bool = false,
        showUpperDivider: Bool = false,
        opacity: Double = 1,
        onTap: @escaping () -> Void
    ) {
        self.showLowerDivider = showLowerDivider
        self.showUpperDivider = showUpperDivider
        self.opacity = opacity
        self.onTap = onTap
    }

    @AppStorage("showListDividers") private var showListDividers: Bool =
        true

    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: ListLayout.DIVIDER_HEIGHT)
            .overlay(
                divider
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private var divider: some View {
        if showListDividers {
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
