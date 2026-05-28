//
//  Birthday.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import Contacts
import EventKit

struct Birthday: Identifiable {
    let contact: CNContact
    let event: EKEvent

    var id: String {
        event.eventIdentifier
    }
}
