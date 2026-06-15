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
    func loadContact(
        for plannerEvent: PlannerEvent
    ) -> CNContact? {
        if let existing = plannerEvent.calendarContext?.birthdayContact {
            return existing
        }

        guard
            let contactId = plannerEvent.calendarContext?
                .birthdayContactIdentifier
        else {
            return nil
        }

        do {
            let contact = try unifiedContact(
                withIdentifier: contactId,
                keysToFetch: [
                    CNContactViewController.descriptorForRequiredKeys()
                ] as [CNKeyDescriptor]
            )
            
            plannerEvent.calendarContext?.birthdayContact = contact
            
            return contact
        } catch {
            assertionFailure(
                "ERROR CNContactStore+Birthdays.loadContact: \(error)"
            )
        }

        return nil
    }
    
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
                calendarContext.birthdayContact = contact
            }
        } catch {
            assertionFailure(
                "ERROR CNContactStore+Birthdays.syncBirthdayContacts: \(error)"
            )
        }
    }
}
