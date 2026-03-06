//
//  Toggle.swift
//  Planner
//
//  Created by Alex Green on 2/9/26.
//

import SwiftUI

struct ToggleView: View {
    let isOn: Bool
    let tint: Color?
    let opacity: Double
    let toggle: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    private var iconName: String {
        !isOn ? "circle" : "circle.inset.filled"
    }

    private var primaryColor: Color {
        !isOn
            ? Color.secondary
            : tint ?? accentColor.color
    }

    var body: some View {
        Image(systemName: iconName)
            .imageScale(.large)
            .foregroundStyle(
                primaryColor,
                Color.secondary
            )
            .contentTransition(
                .symbolEffect(
                    .replace
                )
            )
            .opacity(opacity)
            .contentShape(Circle())
            .onTapGesture(perform: toggle)
    }
}
