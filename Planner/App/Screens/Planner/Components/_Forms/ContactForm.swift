//
//  ContactForm.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import Contacts
import ContactsUI
import SwiftUI

struct ContactFormView: UIViewControllerRepresentable {
    let contactIdentifier: String

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var calendarService: CalendarService

    func makeUIViewController(context: Context) -> UINavigationController {
        guard let contact = loadContact() else {
            // Show empty view in case of load error.
            let vc = UIViewController()
            return UINavigationController(rootViewController: vc)
        }

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

    private func loadContact() -> CNContact? {
        guard calendarService.hasContactsAccess == true else { return nil }

        do {
            return try calendarService.cnContactStore.unifiedContact(
                withIdentifier: contactIdentifier,
                keysToFetch: [
                    CNContactViewController.descriptorForRequiredKeys()
                ] as [CNKeyDescriptor]
            )
        } catch {
            assertionFailure("ERROR ContactForm loadContact: \(error)")
        }

        return nil
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
