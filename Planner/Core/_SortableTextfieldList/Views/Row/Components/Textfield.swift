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
    @Binding var focusedId: UUID?
    let stableId: UUID
    var tint: Color
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

        if focusedId == stableId, !uiView.isFirstResponder {
            // Item has requested focus. Make it the first responder.
            uiView.becomeFirstResponder()
        } else if focusedId == nil, uiView.isFirstResponder {
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
            guard parent.focusedId != parent.stableId else { return }

            Task { @MainActor in
                parent.focusedId = parent.stableId
            }
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

// Note: deprecated toolbar. Now using safe area inset.

// inside makeUIView:
// context.coordinator.configureKeyboardToolbar(for: textField)

// inside Coordinator:
//        func configureKeyboardToolbar(for textView: UITextView) {
//            let container = UIView()
//            container.translatesAutoresizingMaskIntoConstraints = false
//            container.frame.size.height =
//                ListLayout.TOOLBAR_HEIGHT + ListLayout.TOOLBAR_BOTTOM_SPACING
//
//            let toolbar = UIToolbar()
//            toolbar.translatesAutoresizingMaskIntoConstraints = false
//
//            let flexibleSpace = UIBarButtonItem(
//                barButtonSystemItem: .flexibleSpace,
//                target: nil,
//                action: nil
//            )
//
//            // Custom Buttons
//            let iconButtons: [UIBarButtonItem] = parent.toolbarSystemImageNames
//                .map {
//                    systemImageName in
//                    let image = UIImage(systemName: systemImageName)
//                    let button = UIBarButtonItem(
//                        image: image,
//                        style: .plain,
//                        target: self,
//                        action: #selector(toolbarButtonTapped(sender:))
//                    )
//
//                    objc_setAssociatedObject(
//                        button,
//                        &toolbarKey,
//                        systemImageName,
//                        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
//                    )
//
//                    return button
//                }
//
//            // Done Button
//            let done = UIBarButtonItem(
//                barButtonSystemItem: .done,
//                target: self,
//                action: #selector(doneButtonTapped)
//            )
//            toolbar.tintColor = UIColor(parent.tint)
//
//            // Assemble the toolbar.
//            toolbar.items = iconButtons + [flexibleSpace] + [done]
//            container.addSubview(toolbar)
//            NSLayoutConstraint.activate([
//                toolbar.leadingAnchor.constraint(
//                    equalTo: container.leadingAnchor
//                ),
//                toolbar.trailingAnchor.constraint(
//                    equalTo: container.trailingAnchor
//                ),
//                toolbar.topAnchor.constraint(equalTo: container.topAnchor),
//                toolbar.heightAnchor.constraint(
//                    equalToConstant: ListLayout.TOOLBAR_HEIGHT
//                ),
//            ])
//            textView.inputAccessoryView = container
//        }
//        @objc private func toolbarButtonTapped(sender: UIButton) {
//            if let systemImageName = objc_getAssociatedObject(
//                sender,
//                &toolbarKey
//            ) as? String {
//                parent.onTapToolbar(systemImageName)
//            }
//        }
//
//        @objc private func doneButtonTapped() {
//            parent.focusedId = nil
//        }
