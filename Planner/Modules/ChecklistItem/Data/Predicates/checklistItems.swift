//
//  checklistItems.swift
//  Planner
//
//  Created by Alex Green on 6/28/26.
//

import SwiftUI

extension ChecklistItem {
    static func checklistItems(
        parentId: UUID
    ) -> Predicate<ChecklistItem> {
        #Predicate<ChecklistItem> {
            $0.parent?.stableId == parentId
        }
    }

    static func checklistItems(
        stableId: UUID
    ) -> Predicate<ChecklistItem> {
        #Predicate<ChecklistItem> {
            $0.stableId == stableId
        }
    }

    static var rootFolders: Predicate<ChecklistItem> = #Predicate<ChecklistItem>
    {
        $0.parent == nil
    }
}
