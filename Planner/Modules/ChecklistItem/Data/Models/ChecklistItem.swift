//
//  ChecklistItem.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

@Model
class ChecklistItem: ListItemDetails {
    
    var parent: ChecklistItem?

    var stableId: UUID = UUID()

    var title: String = ""
    var type: ChecklistItemType = ChecklistItemType.checklist
    var color: ChecklistItemColor = ChecklistItemColor.red
    var isCompleted: Bool = false
    
    var sortIndex: Double = ChecklistsData.SORT_INDEX_SPACING

    var showCompleted: Bool = false
    
    var height: CGFloat = 0

    @Relationship(
        deleteRule: .cascade,
        inverse: \ChecklistItem.parent
    )
    var items: [ChecklistItem]?

    init(
        title: String = "",
        type: ChecklistItemType = .checklist,
        color: ChecklistItemColor = .red,
        sortIndex: Double = ChecklistsData.SORT_INDEX_SPACING,
        parent: ChecklistItem? = nil
    ) {
        self.title = title
        self.type = type
        self.color = color
        self.sortIndex = sortIndex
        self.parent = parent
        
        parent?.items.safeAppend(self)
    }
}
