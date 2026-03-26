//
//  ActionButton.swift
//  Planner
//
//  Created by Alex Green on 2/8/26.
//

import SwiftUI

// Clean

struct ActionButtonView: View {
    let label: String
    let systemImage: String?
    let color: Color?
    let onTap: () -> Void

    init(
        label: String,
        systemImage: String? = nil,
        color: Color? = nil,
        onTap: @escaping () -> Void
    ) {
        self.label = label
        self.systemImage = systemImage
        self.color = color
        self.onTap = onTap
        self.accentColor = accentColor
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                ActionTextView(label)
            }
            .foregroundStyle(color ?? accentColor.color)
        }
    }
}
