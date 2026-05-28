//
//  ContactForm.swift
//  Planner
//
//  Created by Alex Green on 1/21/26.
//

import Contacts
import ContactsUI
import SwiftUI

struct ContactFormView: UIViewControllerRepresentable {
    let contact: CNContact

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UINavigationController {
        let contactVC = CNContactViewController(for: contact)

        contactVC.allowsEditing = true
        contactVC.allowsActions = true
        contactVC.navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: context.coordinator,
            action: #selector(Coordinator.doneTapped)
        )

        return UINavigationController(rootViewController: contactVC)
    }

    func updateUIViewController(
        _: UINavigationController,
        context _: Context
    ) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    class Coordinator: NSObject {
        let dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        @objc func doneTapped() {
            dismiss()
        }
    }
}
