//
//  TextfieldView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftUI
import UIKit

struct TextfieldView: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    @Binding var height: CGFloat
    var onSubmit: () -> Void

    func makeUIView(context: Context) -> UITextView {
        let textField = UITextView()
        
        textField.delegate = context.coordinator
        textField.isEditable = true
        textField.font = UIFont.systemFont(ofSize: 17)
        textField.isSelectable = true
        textField.backgroundColor = .clear
        textField.isUserInteractionEnabled = true
        textField.isScrollEnabled = false
        textField.textContainerInset = .zero
        textField.textContainer.lineFragmentPadding = 0
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return textField
    }

    private func calculateHeight(
        view: UIView
    ) {
        let size = view.sizeThatFits(
            CGSize(
                width: view.frame.size.width,
                height: CGFloat.greatestFiniteMagnitude
            )
        )

        guard height != size.height else { return }
        DispatchQueue.main.async {
            height = size.height
        }
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }

        calculateHeight(view: uiView)

        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        let parent: TextfieldView

        init(_ parent: TextfieldView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text ?? ""
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if !textView.isFirstResponder {
                parent.isFocused = false
            }
        }

        // Intercept return key so it doesn't add a newline.
        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText replacement: String
        ) -> Bool {
            if replacement == "\n" {
                parent.onSubmit()
                return false  // Don’t insert a newline.
            }
            return true
        }
    }
}
