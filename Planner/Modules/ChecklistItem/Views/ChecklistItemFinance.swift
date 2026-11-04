//
//  ChecklistItemFinance.swift
//  Planner
//
//  Created by Alex Green on 9/25/26.
//

import SwiftUI

struct ChecklistItemFinanceView: View {
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

    private var isSum: Bool {
        item.financeVariant == ChecklistItemFinanceVariant.sum
    }

    private var isCompare: Bool {
        item.financeVariant == ChecklistItemFinanceVariant.compare
    }

    private var isProgressUp: Bool {
        item.financeVariant == ChecklistItemFinanceVariant.progressUp
    }

    private var isProgressDown: Bool {
        item.financeVariant == ChecklistItemFinanceVariant.progressDown
    }

    // MARK: - Body

    var body: some View {
        if item.financeVariant != ChecklistItemFinanceVariant.none {
            ZStack {
                let values = ZStack {
                    if isSum {
                        sumView
                    }

                    if isProgressUp {
                        progressUpView
                    }

                    if isProgressDown {
                        progressDownView
                    }

                    if isCompare {
                        compareView
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
                } else {
                    values
                        .padding(.horizontal, 24)
                        .padding(.bottom)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - View Builders

    // MARK: Sum

    @ViewBuilder
    private var sumView: some View {
        VStack(alignment: .leading, spacing: 4) {
            header(valueString(sum))
                .foregroundStyle(Color.label)

            if !positiveSum.isZero && !negativeSum.isZero {
                VStack(spacing: 2) {
                    if !positiveSum.isZero {
                        signedValue(positiveSum, isNegative: false)
                    }

                    if !negativeSum.isZero {
                        signedValue(negativeSum, isNegative: true)
                    }
                }
            }
        }
    }

    // MARK: Compare

    @ViewBuilder
    private var compareView: some View {
        VStack(alignment: .leading, spacing: 6) {
            header(valueString(sum))
                .foregroundStyle(Color.label)

            GeometryReader { geometry in
                let width = geometry.size.width

                let positive = abs(positiveSum)
                let negative = abs(negativeSum)
                let largest = max(positive, negative)

                let hasValues = !largest.isZero

                let positiveProgress =
                    hasValues
                    ? positive / largest
                    : Decimal.zero

                let negativeProgress =
                    hasValues
                    ? negative / largest
                    : Decimal.zero

                VStack(alignment: .leading, spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        valueBar(
                            color: Color.green,
                            width: width,
                            progress: positiveProgress
                        )
                        signedValue(positiveSum, isNegative: false)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        valueBar(
                            color: Color.red,
                            width: width,
                            progress: negativeProgress
                        )
                        signedValue(negativeSum, isNegative: true)
                    }
                }
                .animateUserAction(from: negative)
                .animateUserAction(from: positive)
            }
            .frame(height: 50)
        }
    }

    private func valueBar(color: Color, width: CGFloat, progress: Decimal)
        -> some View
    {
        Capsule()
            .fill(color)
            .frame(
                width: progress.isZero
                    ? 8
                    : width
                        * CGFloat(
                            NSDecimalNumber(
                                decimal: progress
                            ).doubleValue
                        )
            )
            .frame(height: 8)
    }

    // MARK: Progress

    @ViewBuilder
    private var progressDownView: some View {
        progressView(
            value: negativeSum,
            total: positiveSum,
            progressColor: Color.red,
            barColor: Color.green
        )
    }

    @ViewBuilder
    private var progressUpView: some View {
        progressView(
            value: positiveSum,
            total: negativeSum,
            progressColor: Color.green,
            barColor: Color.red
        )
    }

    @ViewBuilder
    private func progressView(
        value: Decimal,
        total: Decimal,
        progressColor: Color,
        barColor: Color
    ) -> some View {
        let progress =
            value.isZero
            ? 0
            : total.isZero
                ? 1
                : NSDecimalNumber(decimal: abs(value) / abs(total)).doubleValue

        let percentage: Double = progress * 100

        let isOver =
            isProgressUp
            ? sum > 0
            : sum < 0

        let label =
            abs(sum).formatted(.currency(code: "USD"))
            + (isOver ? " over" : " remaining")

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                header("\(Int(floor(percentage)))%")
                    .foregroundStyle(Color.label)

                Spacer()

                Text(label)
                    .font(
                        .system(size: 10, weight: .medium, design: .rounded)
                    )
                    .foregroundStyle(Color.secondary)
            }

            VStack(spacing: 2) {
                GeometryReader { geometry in
                    ProgressBarView(
                        width: geometry.size.width,
                        progress: progress,
                        color: total.isZero
                            ? Color.tertiary : barColor.opacity(0.2),
                        progressColor: progressColor
                    )
                }
                .frame(height: 10)

                HStack {
                    signedValue(value, isNegative: progressColor == Color.red)
                    Spacer()
                    signedValue(total, isNegative: progressColor == Color.green)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Values

    @ViewBuilder
    private func header(_ value: String) -> some View {
        Text(value)
            .font(
                .system(size: 12, weight: .black, design: .rounded)
            )
    }

    @ViewBuilder
    private func signedValue(_ value: Decimal, isNegative: Bool)
        -> some View
    {
        AdornedValue(
            signedValueString(value, isNegative: isNegative),
            color: isNegative ? Color.red : Color.green,
            scale: 0.7
        )
    }

    // MARK: - Functions

    private func signedValueString(_ value: Decimal, isNegative: Bool) -> String
    {
        "\(isNegative ? "-" : "+")\(valueString(abs(value)))"
    }

    private func valueString(_ value: Decimal) -> String {
        "\(value.formatted(.currency(code: "USD")))"
    }
}
