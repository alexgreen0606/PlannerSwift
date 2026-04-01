//
//  ActionText.swift
//  Planner
//
//  Created by Alex Green on 3/26/26.
//

import SwiftUI

// Clean

struct ActionTextView: View {
    private let text: String
    private let color: Color?

    init(_ text: String, color: Color? = nil) {
        self.text = text
        self.color = color
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    var body: some View {
        Text(text)
            .font(
                .system(size: 14, weight: .black, design: .rounded)
            )
            .foregroundStyle(
                color ?? accentColor.color
            )
    }
}
