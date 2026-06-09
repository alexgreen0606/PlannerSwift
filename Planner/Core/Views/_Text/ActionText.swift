//
//  ActionText.swift
//  Planner
//
//  Created by Alex Green on 3/26/26.
//

import SwiftUI

struct ActionText: View {
    private let text: String

    init(_ text: String, color: Color? = nil) {
        self.text = text

        customColor = color
    }

    private let customColor: Color?

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        Text(text)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .font(
                .system(
                    size: Layout.TEXT,
                    weight: .black,
                    design: .rounded
                )
            )
            .foregroundStyle(
                customColor ?? accentColor.color
            )
    }
}
