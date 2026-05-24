//
//  YearSectionHeader.swift
//  Planner
//
//  Created by Alex Green on 3/27/26.
//

import SwiftUI

struct YearSectionHeader: View {
    private let year: String

    init(_ year: String) {
        self.year = year
    }

    // MARK: - Body

    var body: some View {
        Text(year)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundColor(.secondary)
            .frame(
                maxWidth: .infinity,
                alignment: .trailing
            )
    }
}
