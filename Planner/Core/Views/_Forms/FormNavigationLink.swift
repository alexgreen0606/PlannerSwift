//
//  FormNavigationLink.swift
//  Planner
//
//  Created by Alex Green on 6/14/26.
//

import SwiftUI

struct FormNavigationLinkView: View {
    private let iconConfig: IconConfig
    private let label: String

    init(
        iconConfig: IconConfig,
        label: String
    ) {
        self.iconConfig = iconConfig
        self.label = label
    }

    // MARK: - Body

    var body: some View {
        HStack {
            Image(systemName: iconConfig.name)
                .imageScale(.medium)
                .foregroundStyle(
                    iconConfig.primaryColor,
                    iconConfig.secondaryColor
                )
            Text("")
            Spacer()
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
