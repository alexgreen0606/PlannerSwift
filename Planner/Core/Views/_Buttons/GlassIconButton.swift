//
//  GlassIconButton.swift
//  Planner
//
//  Created by Alex Green on 5/12/26.
//

import SwiftUI

struct GlassIconButtonView: View {
    private let systemImageName: String
    private let prominent: Bool
    private let disabled: Bool
    private let color: Color?
    private let onTap: () -> Void

    init(
        systemImageName: String,
        prominent: Bool = false,
        disabled: Bool = false,
        color: Color? = nil,
        onTap: @escaping () -> Void
    ) {
        self.systemImageName = systemImageName
        self.prominent = prominent
        self.disabled = disabled
        self.color = color
        self.onTap = onTap
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        let button = Button {
            guard !disabled else { return }
            
            onTap()
        } label: {
            Image(systemName: systemImageName)
                .imageScale(.large)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .frame(width: 32, height: 32)
        }
        .buttonBorderShape(.circle)
        .tint(disabled ? Color.tertiary : color ?? accentColor.color)

        if prominent {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }
}
