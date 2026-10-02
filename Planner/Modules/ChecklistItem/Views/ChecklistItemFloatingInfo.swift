//
//  ChecklistItemFloatingInfo.swift
//  Planner
//
//  Created by Alex Green on 9/25/26.
//

import SwiftUI

struct ChecklistItemFloatingInfoView: View {
    let item: ChecklistItem

    private var positiveSum: Decimal {
        item.positiveSum
    }

    private var negativeSum: Decimal {
        item.negativeSum
    }

    private var sum: Decimal {
        item.sum
    }

    // MARK: - Body

    var body: some View {
        if item.showItemValues && (!positiveSum.isZero || !negativeSum.isZero) {
            HStack {
                Spacer()
                valueChip(sum)
            }
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private func valueChip(_ value: Decimal, scale: CGFloat = 1) -> some View {
        AdornedValue(
            "\(value.formatted(.currency(code: "USD")))",
            color: value < 0 ? Color.red : Color.green,
            scale: scale
        )
        .padding(8 * scale)
        .glassEffect(
            .regular,
            in: .rect(
                cornerRadius: 12 * scale
            )
        )
    }
}
