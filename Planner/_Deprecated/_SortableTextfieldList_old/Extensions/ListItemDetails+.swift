//
//  ListItemDetails.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import Foundation

extension ListItemDetails {
    var transitionId: String {
        stableId.uuidString
    }

    var safeDraft: Self {
        if let draft {
            return draft
        }

        let newDraft = Self(draftOf: self)
        draft = newDraft
        return newDraft
    }
}
