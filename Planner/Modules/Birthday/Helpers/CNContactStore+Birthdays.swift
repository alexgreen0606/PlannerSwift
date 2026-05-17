//
//  CNContactStore.swift
//  Planner
//
//  Created by Alex Green on 4/11/26.
//

import Contacts
import ContactsUI
import EventKit

extension CNContactStore {
    func loadBirthdays(for birthdayEventMap: [String: EKEvent]) -> [Birthday] {
        var birthdays: [Birthday] = []

        let store = CNContactStore()
        do {
            let contacts = try store.unifiedContacts(
                matching: CNContact.predicateForContacts(
                    withIdentifiers: Array(birthdayEventMap.keys)
                ),
                keysToFetch: [
                    CNContactViewController.descriptorForRequiredKeys(),
                ] as [CNKeyDescriptor]
            )

            for contact in contacts {
                guard let event = birthdayEventMap[contact.identifier]
                else { continue }

                birthdays.append(Birthday(contact: contact, event: event))
            }

        } catch {
            assertionFailure("ERROR CNContactStore.loadBirthdays: \(error)")
        }

        return birthdays.sorted { $0.event.title < $1.event.title }
    }
}
