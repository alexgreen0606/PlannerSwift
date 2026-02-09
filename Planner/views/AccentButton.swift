//
//  AccentButton.swift
//  Planner
//
//  Created by Alex Green on 2/8/26.
//

import SwiftUI

struct AccentButtonView: View {
    let label: String
    let systemImage: String
    let onTap: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(label)
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .tint(accentColor.swiftUIColor)
    }
}
