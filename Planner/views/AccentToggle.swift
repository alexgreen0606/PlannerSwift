//
//  AccentToggle.swift
//  Planner
//
//  Created by Alex Green on 2/9/26.
//

import SwiftUI

struct AccentToggleView: View {
    let isOn: Bool
    let toggle: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    private var iconName: String {
        !isOn ? "circle" : "circle.inset.filled"
    }

    private var primaryColor: Color {
        !isOn
            ? Color(uiColor: .secondaryLabel)
            : accentColor.swiftUIColor
    }

    private var secondaryColor: Color {
        !isOn
            ? Color(uiColor: .secondaryLabel)
            : Color(uiColor: .secondaryLabel)
    }

    var body: some View {
        Image(systemName: iconName)
            .imageScale(.large)
            .foregroundStyle(
                primaryColor,
                secondaryColor
            )
            .contentTransition(
                .symbolEffect(
                    .replace
                )
            )
            .contentShape(Circle())
            .onTapGesture(perform: toggle)
    }
}
