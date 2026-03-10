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
    let systemImage: String
    let onTap: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack {
                Image(systemName: systemImage)
                Text(label)
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .padding(.bottom, 8)
        }
        .tint(accentColor.color)
    }
}
