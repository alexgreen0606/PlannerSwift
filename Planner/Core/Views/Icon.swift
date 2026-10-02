//
//  Icon.swift
//  Planner
//
//  Created by Alex Green on 9/28/26.
//

import SwiftUI

struct Icon: View {
    private let config: IconConfig

    init(
        _ config: IconConfig
    ) {
        self.config = config
    }

    // MARK: - Body

    var body: some View {
        Image(systemName: config.name)
            .foregroundStyle(
                config.primaryColor,
                config.secondaryColor
            )
    }
}
