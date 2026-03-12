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
    private let onTap: () -> Void

    init(
        showLowerDivider: Bool = false,
        showUpperDivider: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.showLowerDivider = showLowerDivider
        self.showUpperDivider = showUpperDivider
        self.onTap = onTap
    }

    @AppStorage("showListDividers") private var showListDividers: Bool =
        true

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

    @ViewBuilder
    private var divider: some View {
        if showListDividers {
            VStack {
                if showLowerDivider {
                    Spacer()
                    Divider().background(.tertiary)
                } else if showUpperDivider {
                    Divider().background(.tertiary)
                    Spacer()
                }
            }
        }
    }

}
