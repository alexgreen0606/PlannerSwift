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

    private var showIndividualSums: Bool {
        !positiveSum.isZero && !negativeSum.isZero
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
        if item.showItemValues && (!positiveSum.isZero || !negativeSum.isZero) {
            let values = VStack {
                totalValue

                if showIndividualSums {
                    HStack {
                        individualValue(positiveSum)
                        Spacer()
                        individualValue(negativeSum)
                    }
                }
            }
            .animateUserAction(from: sum)

            if isGlassChip {
                values
                    .padding(8)
                    .glassEffect(
                        .regular.interactive(),
                        in: .rect(
                            cornerRadius: 12
                        )
                    )
                    .padding(.horizontal, showIndividualSums ? 16 : 0)
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

            if showIndividualSums {
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
