//
//  EmptyLabel.swift
//  Planner
//
//  Created by Alex Green on 1/15/26.
//

import SwiftUI

struct EmptyLabel: View {
    private let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(Color(uiColor: .tertiaryLabel))
            .frame(height: UIConstants.emptyLabelHeight)
    }
}
