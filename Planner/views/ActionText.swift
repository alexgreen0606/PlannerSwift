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

    init(_ text: String) {
        self.text = text
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    var body: some View {
        Text(text)
            .font(
                .system(size: 14, weight: .black, design: .rounded)
            )
            .foregroundStyle(
                accentColor.color
            )
    }
}
