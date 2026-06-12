//
//  ContactService.swift
//  Planner
//
//  Created by Alex Green on 6/11/26.
//

import Contacts

final class ContactService {
    static let shared = ContactService()

    let store = CNContactStore()

    private init() {}
}
