//
//  ActionButtonView.swift
//  Planner
//
//  Created by Alex Green on 2/8/26.
//

import SwiftUI

struct ActionButtonView: View {
    let label: String
    let systemImage: String
    let color: Color?
    let spacing: CGFloat
    let endAdornment: Bool
    let onTap: () -> Void

    init(
        label: String,
        systemImage: String,
        color: Color? = nil,
        spacing: CGFloat = 6,
        endAdornment: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.label = label
        self.systemImage = systemImage
        self.color = color
        self.onTap = onTap
        self.spacing = spacing
        self.endAdornment = endAdornment
        accentColor = accentColor
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: spacing) {
                if !endAdornment {
                    adornment
                }

                ActionTextView(label, color: color)

                if endAdornment {
                    adornment
                }
            }
            .foregroundStyle(color ?? accentColor.color)
        }
    }

    private var adornment: some View {
        Image(systemName: systemImage)
            .imageScale(.medium)
            .fontWeight(.bold)
            .fontDesign(.rounded)
    }
}
