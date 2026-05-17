//
//  GlassIconButton.swift
//  Planner
//
//  Created by Alex Green on 5/12/26.
//

import SwiftUI

struct GlassIconButtonView: View {
    let systemImage: String
    let color: Color?
    let onTap: () -> Void

    init(systemImage: String, color: Color? = nil, onTap: @escaping () -> Void) {
        self.systemImage = systemImage
        self.color = color
        self.onTap = onTap
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

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
        .foregroundStyle(color ?? accentColor.color)
        .tint(color ?? accentColor.color)
    }
}
