//
//  ChecklistItemValue.swift
//  Planner
//
//  Created by Alex Green on 9/25/26.
//

import SwiftData
import SwiftUI

struct ChecklistItemValueView: View {
    let value: Decimal

    // MARK: - Body

    var body: some View {
        Text(value, format: .currency(code: "USD"))
            .font(
                .system(size: 12, weight: .black, design: .rounded)
            )
            .foregroundStyle(
                value < 0 ? Color.red : Color.green
            )
    }
}
