//
//  deleteSingleItemMessage.swift
//  Planner
//
//  Created by Alex Green on 5/28/26.
//

func deleteSingleItemMessage(title: String, type: String, inForm: Bool) -> String {
    "Delete\(inForm ? " this" : "") \(type)\(inForm ? "" : " \"\(title)\"")?"
}
