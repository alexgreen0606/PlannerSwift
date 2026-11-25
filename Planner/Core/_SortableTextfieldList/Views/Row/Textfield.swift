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
    var tint: Color
    var shouldResign: Bool
    var isFocused: Bool
    var onEndEditing: () -> Void
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

        if shouldResign, uiView.isFirstResponder {
            // List has requested blur. Resign the first responder.
            uiView.resignFirstResponder()
            return
        }

        if isFocused, !uiView.isFirstResponder {
            // Item has requested focus. Make it the first responder.
            uiView.becomeFirstResponder()
        }
    }

    /// Sizes the text view to fit its text at SwiftUI's proposed width.
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UITextView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width, width > 0, width.isFinite else {
            return nil
        }

        let fittedSize = uiView.sizeThatFits(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )

        return CGSize(width: width, height: fittedSize.height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
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
            // Ask SwiftUI to re-measure so the row grows/shrinks with the text.
            textView.invalidateIntrinsicContentSize()
        }

        func textViewDidEndEditing(_: UITextView) {
            parent.onEndEditing()
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
