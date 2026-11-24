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
        for plannerEventMap: [String: PlannerEvent],
        calendarService: CalendarService
    ) {
        let contactsAccess = calendarService.hasContactsAccess
        
        guard
            contactsAccess == true
        else {
            if contactsAccess == false {
                // Clear references to contacts data when access is denied.
                for event in plannerEventMap.values {
                    event.eKEventContext?.birthdayContact = nil
                    event.eKEventContext?.birthdayThumbnailData = nil
                }
            }

            return
        }

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
                    let eKEventContext = event.eKEventContext
                else { continue }

                eKEventContext.birthdayContactIdentifier = contact.identifier
                eKEventContext.birthdayThumbnailData =
                    contact.thumbnailImageData
                eKEventContext.birthdayContact = contact
            }
        } catch {
            assertionFailure(
                "ERROR CNContactStore+Birthdays syncBirthdayContacts: \(error)"
            )
        }
    }
}
