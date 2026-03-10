//
//  EmptyLabel.swift
//  Planner
//
//  Created by Alex Green on 1/15/26.
//

import SwiftUI

// Clean

struct EmptyLabelView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 16, weight: .heavy, design: .rounded))
            .foregroundStyle(Color(uiColor: .tertiaryLabel))
            .frame(height: UiConstants.emptyLabelHeight)
    }
}
