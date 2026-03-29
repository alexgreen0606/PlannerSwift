//
//  Textfield.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI
import UIKit

// Clean

struct TextfieldView: UIViewRepresentable {
    @Binding var focusedId: UUID?
    @Binding var text: String
    @Binding var height: CGFloat
    let itemId: UUID
    var accentColor: Color
    var toolbarSystemImageNames: [String]
    var onTapToolbar: (String) -> Void
    var onEnter: () -> Void

    func makeUIView(context: Context) -> UITextView {
        let textField = UITextView()

        textField.delegate = context.coordinator
        context.coordinator.textView = textField
        context.coordinator.configureKeyboardToolbar(for: textField)

        textField.isEditable = true
        textField.font = UIFont.systemFont(ofSize: ListLayout.FONT_SIZE)
        textField.isSelectable = true
        textField.backgroundColor = .clear
        textField.isUserInteractionEnabled = true
        textField.isScrollEnabled = false
        textField.textContainerInset = .zero
        textField.textContainer.lineFragmentPadding = 0
        textField.setContentCompressionResistancePriority(
            .defaultLow,
            for: .horizontal
        )

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
        context.coordinator.parent = self

        if uiView.text != text {
            uiView.text = text
        }

        calculateHeight(view: uiView)

        if focusedId == itemId && !uiView.isFirstResponder {
            // Focus textfield when clicked.
            uiView.becomeFirstResponder()
        } else if focusedId == nil && uiView.isFirstResponder {
            // Blur textfield when no items should be focused.
            uiView.resignFirstResponder()
        }
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
            parent.text = textView.text ?? ""
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            guard parent.focusedId != parent.itemId else { return }

            Task { @MainActor in
                parent.focusedId = parent.itemId
            }
        }

        // Override return key so it doesn't add a newline.
        func textView(
            _ textView: UITextView,
            shouldChangeTextIn range: NSRange,
            replacementText replacement: String
        ) -> Bool {
            if replacement == "\n" {
                parent.onEnter()
                return false
            }
            return true
        }

        func configureKeyboardToolbar(for textView: UITextView) {
            let toolbarHeight: CGFloat = 44
            let toolbarBottomPadding: CGFloat = 8

            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.frame.size.height = toolbarHeight + toolbarBottomPadding

            let toolbar = UIToolbar()
            toolbar.translatesAutoresizingMaskIntoConstraints = false

            let flexibleSpace = UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil
            )

            // Custom Buttons.
            let iconButtons: [UIBarButtonItem] = parent.toolbarSystemImageNames
                .map {
                    systemImageName in
                    let image = UIImage(systemName: systemImageName)
                    let button = UIBarButtonItem(
                        image: image,
                        style: .plain,
                        target: self,
                        action: #selector(toolbarButtonTapped(sender:))
                    )

                    objc_setAssociatedObject(
                        button,
                        &toolbarKey,
                        systemImageName,
                        .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                    )

                    return button
                }

            // Done Button.
            let done = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(doneButtonTapped)
            )
            done.tintColor = UIColor(parent.accentColor)

            // Build the toolbar.
            toolbar.items = iconButtons + [flexibleSpace] + [done]
            container.addSubview(toolbar)
            NSLayoutConstraint.activate([
                toolbar.leadingAnchor.constraint(
                    equalTo: container.leadingAnchor
                ),
                toolbar.trailingAnchor.constraint(
                    equalTo: container.trailingAnchor
                ),
                toolbar.topAnchor.constraint(equalTo: container.topAnchor),
                toolbar.heightAnchor.constraint(equalToConstant: toolbarHeight),
            ])
            textView.inputAccessoryView = container
        }

        @objc private func toolbarButtonTapped(sender: UIButton) {
            if let systemImageName = objc_getAssociatedObject(
                sender,
                &toolbarKey
            ) as? String {
                parent.onTapToolbar(systemImageName)
            }
        }

        @objc private func doneButtonTapped() {
            parent.focusedId = nil
        }

    }
}
