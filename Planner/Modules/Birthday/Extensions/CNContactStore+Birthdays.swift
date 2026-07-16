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
        for plannerEvent: PlannerEvent,
        calendarService: CalendarService
    ) -> CNContact? {
        guard
            calendarService.hasContactsAccess == true
        else { return nil }

        if let existing = plannerEvent.eKEventContext?.birthdayContact {
            return existing
        }

        guard
            let contactId = plannerEvent.eKEventContext?
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

            plannerEvent.eKEventContext?.birthdayContact = contact

            return contact
        } catch {
            assertionFailure(
                "ERROR CNContactStore+Birthdays loadContact: \(error)"
            )
        }

        return nil
    }

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
