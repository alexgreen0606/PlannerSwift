//
//  CurrencyTextfield.swift
//  Planner
//
//  Created by Benoit Pasquier on 10/2/22.
//  Customized by Alex Green on 9/28/26.
//

import Foundation
import SwiftUI
import UIKit

// MARK: - UIKit

class CurrencyField: UITextField {
    @Binding private var value: Int
    private let customTextColor: Color

    init(
        value: Binding<Int>,
        textColor: Color
    ) {
        self._value = value
        self.customTextColor = textColor
        super.init(frame: .zero)
        setupViews()
    }

    private let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: superview)
        addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        addTarget(self, action: #selector(resetSelection), for: .allTouchEvents)
        keyboardType = .numberPad
        textAlignment = .right
        sendActions(for: .editingChanged)
    }

    override func deleteBackward() {
        text = textValue.digits.dropLast().string
        sendActions(for: .editingChanged)
    }

    private func setupViews() {
        font = .systemFont(ofSize: 16, weight: .black)
        textColor = UIColor(customTextColor)
        setInitialValue()
    }

    private func setInitialValue() {
        if value > 0 {
            let val = Double(value)
            let decimalValue = Decimal(val / 100.0)
            text = currency(from: decimalValue)
        }
    }

    @objc private func editingChanged() {
        text = currency(from: decimal)
        resetSelection()
        updateValue()
    }

    @objc private func resetSelection() {
        selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
    }

    private func updateValue() {
        DispatchQueue.main.async { [weak self] in
            self?.value = self?.intValue ?? 0
        }
    }

    private var textValue: String {
        return text ?? ""
    }

    private var decimal: Decimal {
        return textValue.decimal / pow(10, formatter.maximumFractionDigits)
    }

    private var intValue: Int {
        return NSDecimalNumber(decimal: decimal * 100).intValue
    }

    private func currency(from decimal: Decimal) -> String {
        return formatter.string(for: decimal) ?? ""
    }
}

// MARK: - SwiftUI

struct CurrencyTextFieldView: UIViewRepresentable {
    @Binding var value: Int
    let textColor: Color

    func makeUIView(context: Context) -> CurrencyField {
        CurrencyField(
            value: $value,
            textColor: textColor
        )
    }

    func updateUIView(_ uiView: CurrencyField, context: Context) {
        uiView.textColor = UIColor(textColor)
    }
}

extension StringProtocol where Self: RangeReplaceableCollection {
    var digits: Self { filter(\.isWholeNumber) }
}

extension String {
    var decimal: Decimal { Decimal(string: digits) ?? 0 }
}

extension LosslessStringConvertible {
    var string: String { .init(self) }
}
