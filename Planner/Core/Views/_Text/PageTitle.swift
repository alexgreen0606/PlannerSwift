//
//  PageTitle.swift
//  Planner
//
//  Created by Alex Green on 11/20/26.
//

import SwiftUI

struct PageTitle: View {
    private let title: String

    init(_ title: String) {
        self.title = title
    }

    // MARK: - Body

    var body: some View {
        Text(title)
            .font(
                .system(
                    size: 28,
                    weight: .bold,
                    design: .rounded
                )
            )
    }
}
