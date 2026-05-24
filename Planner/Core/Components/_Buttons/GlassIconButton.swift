//
//  GlassIconButton.swift
//  Planner
//
//  Created by Alex Green on 5/12/26.
//

import SwiftUI

struct GlassIconButtonView: View {
    private let systemImage: String
    private let onTap: () -> Void

    init(systemImage: String, color: Color? = nil, onTap: @escaping () -> Void) {
        self.systemImage = systemImage
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
            Image(systemName: systemImage)
                .imageScale(.large)
                .padding(4)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .tint(customColor ?? accentColor.color)
    }
}
