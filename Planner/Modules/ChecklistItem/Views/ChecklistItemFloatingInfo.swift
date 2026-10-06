//
//  ChecklistItemFloatingInfo.swift
//  Planner
//
//  Created by Alex Green on 9/25/26.
//

import SwiftUI

struct ChecklistItemFloatingInfoView: View {
    private let item: ChecklistItem
    private let completed: Bool

    init(item: ChecklistItem, completed: Bool = false) {
        self.item = item
        self.completed = completed
    }

    private var positiveSum: Decimal {
        item.positiveSum(completed: completed)
    }

    private var negativeSum: Decimal {
        item.negativeSum(completed: completed)
    }

    private var sum: Decimal {
        positiveSum + negativeSum
    }

    private var isGlassChip: Bool {
        item.type == .checklist
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
        if item.isFinanceTracker {
            let values = VStack {
                totalValue

                HStack {
                    individualValue(positiveSum)
                    Spacer()
                    individualValue(negativeSum)
                }
            }

            if isGlassChip {
                values
                    .padding(8)
                    .glassEffect(
                        .regular.interactive(),
                        in: .rect(
                            cornerRadius: 12
                        )
                    )
                    .padding(.horizontal)
            } else {
                values
                    .padding(.horizontal, 48)
                    .padding(.bottom)
            }
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var totalValue: some View {
        VStack {
            ChecklistItemValueView(value: sum)

            GeometryReader { geometry in
                let width = geometry.size.width
                let hasValues = !positiveSum.isZero || !negativeSum.isZero
                let barWidth = max(0, width - 2)

                HStack(spacing: 0) {
                    Capsule()
                        .fill(hasValues ? Color.green : Color.tertiary)
                        .frame(
                            width: hasValues
                                ? barWidth * progress
                                : barWidth / 2
                        )
                        .frame(height: 10)

                    Spacer(minLength: 0)

                    Capsule()
                        .fill(hasValues ? Color.red : Color.tertiary)
                        .frame(
                            width: hasValues
                                ? barWidth * (1 - progress)
                                : barWidth / 2
                        )
                        .frame(height: 10)
                }
                .animateUserAction(from: progress)
            }
            .frame(height: 10)
        }
    }

    @ViewBuilder
    private func individualValue(_ value: Decimal) -> some View {
        AdornedValue(
            "\(value > 0 ? "+" : "")\(value.formatted(.currency(code: "USD")))",
            color: value == 0
                ? Color.secondary : value < 0 ? Color.red : Color.green,
            scale: 0.7
        )
    }
}
