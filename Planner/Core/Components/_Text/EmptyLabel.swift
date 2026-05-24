//
//  EmptyLabel.swift
//  Planner
//
//  Created by Alex Green on 1/15/26.
//

import SwiftUI

struct EmptyLabel: View {
    private let text: String
    private let scale: Double

    init(_ text: String, scale: Double = 1) {
        self.text = text
        self.scale = scale
    }

    // MARK: - Body

    var body: some View {
        Text(text)
            .multilineTextAlignment(.center)
            .font(.system(size: 16 * scale, weight: .heavy, design: .rounded))
            .foregroundStyle(.tertiary)
    }
}
