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
    private let onTap: () -> Void

    init(
        systemImageName: String,
        prominent: Bool = false,
        onTap: @escaping () -> Void
    ) {
        self.systemImageName = systemImageName
        self.prominent = prominent
        self.onTap = onTap
    }

    // MARK: - Body

    var body: some View {
        let button = Button {
            onTap()
        } label: {
            Image(systemName: systemImageName)
                .imageScale(.large)
                .fontWeight(.semibold)
                .fontDesign(.rounded)
                .frame(width: 32, height: 32)
        }
        .buttonBorderShape(.circle)

        if prominent {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }
}
