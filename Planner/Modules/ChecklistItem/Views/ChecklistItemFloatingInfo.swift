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

    private var progress: CGFloat {
        let positive = NSDecimalNumber(decimal: positiveSum)
            .doubleValue

        let negative = abs(
            NSDecimalNumber(decimal: negativeSum)
                .doubleValue
        )

        let total = positive + negative

        guard total > 0 else { return 0 }

        return CGFloat(positive / total)
    }

    // MARK: - Body

    var body: some View {
        if item.showItemValues && (!positiveSum.isZero || !negativeSum.isZero) {
            VStack {
                totalValue
                HStack {
                    individualValue(positiveSum)
                    Spacer()
                    individualValue(negativeSum)
                }
            }
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var totalValue: some View {
        VStack {
            ChecklistItemValueView(value: item.sum)

            GeometryReader { geometry in
                HStack {
                    Capsule()
                        .fill(Color.green)
                        .frame(
                            width: max(
                                0,
                                geometry.size.width * progress - 2
                            )
                        )
                        .frame(height: 10)

                    Spacer()

                    Capsule()
                        .fill(Color.red)
                        .frame(
                            width: max(
                                0,
                                geometry.size.width * (1 - progress) - 2
                            )
                        )
                        .frame(height: 10)
                }
            }
            .frame(height: 10)
        }
    }

    @ViewBuilder
    private func individualValue(_ value: Decimal) -> some View {
        AdornedValue(
            "\(value > 0 ? "+" : "")\(value.formatted(.currency(code: "USD")))",
            color: value < 0 ? Color.red : Color.green,
            scale: 0.7
        )
    }
}
