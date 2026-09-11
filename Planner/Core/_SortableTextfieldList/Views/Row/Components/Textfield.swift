//
//  Textfield.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI
import UIKit

struct TextfieldView: UIViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    var tint: Color
    var isNothingFocused: Bool
    var isFocused: Bool
    var onBecameFirstResponder: () -> Void
    var onEnter: () -> Void

    func makeUIView(context: Context) -> UITextView {
        let textField = UITextView()

        textField.delegate = context.coordinator
        context.coordinator.textView = textField

        textField.isEditable = true
        textField.isSelectable = true
        textField.isScrollEnabled = false
        textField.isUserInteractionEnabled = true

        textField.font = UIFont.systemFont(ofSize: ListLayout.FONT_SIZE)
        textField.backgroundColor = .clear

        textField.textContainerInset = .zero
        textField.textContainer.lineFragmentPadding = 0
        textField.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )

        return textField
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.parent = self

        if uiView.text != text {
            uiView.text = text
        }

        calculateHeight(view: uiView)

        if isFocused, !uiView.isFirstResponder {
            // Item has requested focus. Make it the first responder.
            uiView.becomeFirstResponder()
        } else if isNothingFocused, uiView.isFirstResponder {
            // List has requested blur. Resign the first responder.
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    /// Dynamically update the height as text grows/lines increase.
    private func calculateHeight(view: UIView) {
        let size = view.sizeThatFits(
            CGSize(
                width: view.frame.size.width,
                height: CGFloat.greatestFiniteMagnitude
            )
        )

        guard height != size.height else { return }

        height = size.height
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextfieldView
        weak var textView: UITextView?

        init(_ parent: TextfieldView) {
            self.parent = parent
        }

        private var toolbarKey: UInt8 = 0

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        /// Inform the list when this textfield has claimed focus.
        func textViewDidBeginEditing(_: UITextView) {
            parent.onBecameFirstResponder()
        }

        /// Override return key so it doesn't add a newline.
        func textView(
            _: UITextView,
            shouldChangeTextIn _: NSRange,
            replacementText replacement: String
        ) -> Bool {
            if replacement == "\n" {
                parent.onEnter()
                return false
            }
            return true
        }
    }
}
