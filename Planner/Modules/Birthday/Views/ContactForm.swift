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
    let plannerEvent: PlannerEvent

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var calendarService: CalendarService

    func makeUIViewController(context: Context) -> UINavigationController {
        guard
            let contact = ContactService.shared.store.loadContact(
                for: plannerEvent,
                calendarService: calendarService
            )
        else {
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
