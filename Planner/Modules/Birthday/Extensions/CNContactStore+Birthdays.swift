//
//  CNContactStore+Birthdays.swift
//  Planner
//
//  Created by Alex Green on 4/11/26.
//

import Contacts
import ContactsUI
import EventKit

extension CNContactStore {
    func syncBirthdayContacts(
        /// Maps contact IDs to planner events for birthdays.
        for plannerEventMap: [String: PlannerEvent]
    ) {
        do {
            let contacts = try unifiedContacts(
                matching: CNContact.predicateForContacts(
                    withIdentifiers: Array(plannerEventMap.keys)
                ),
                keysToFetch: [
                    CNContactViewController.descriptorForRequiredKeys()
                ] as [CNKeyDescriptor]
            )

            for contact in contacts {
                guard let event = plannerEventMap[contact.identifier],
                    let calendarContext = event.calendarContext
                else { continue }

                calendarContext.birthdayContactIdentifier = contact.identifier
                calendarContext.birthdayThumbnailData =
                    contact.thumbnailImageData
            }
        } catch {
            assertionFailure(
                "ERROR CNContactStore+Birthdays.syncBirthdayContacts: \(error)"
            )
        }
    }
}
