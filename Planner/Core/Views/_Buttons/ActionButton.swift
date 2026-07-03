//
//  ActionButton.swift
//  Planner
//
//  Created by Alex Green on 2/8/26.
//

import SwiftUI

struct ActionButtonView: View {
    private let label: String
    private let systemImage: String?
    private let endAdornment: Bool
    private let spacing: CGFloat
    private let onTap: () -> Void

    init(
        label: String,
        systemImage: String? = nil,
        endAdornment: Bool = false,
        color: Color? = nil,
        spacing: CGFloat = 6,
        onTap: @escaping () -> Void
    ) {
        self.label = label
        self.systemImage = systemImage
        self.endAdornment = endAdornment
        self.spacing = spacing
        self.onTap = onTap

        customColor = color
    }

    private let customColor: Color?

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: spacing) {
                if !endAdornment {
                    adornment
                }

                ActionText(label, color: customColor)

                if endAdornment {
                    adornment
                }
            }
            .foregroundStyle(customColor ?? accentColor.swiftUiColor)
        }
    }

    // MARK: - View Builder

    @ViewBuilder
    private var adornment: some View {
        if let systemImage {
            Image(systemName: systemImage)
                .font(
                    .system(
                        size: Layout.TEXT,
                        weight: .semibold,
                        design: .rounded
                    )
                )
        }
    }
}
