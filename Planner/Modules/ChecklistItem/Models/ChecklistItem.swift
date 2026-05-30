//
//  ChecklistItem.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData

@available(iOS 26.0, *)
@Model
class ChecklistItem: ListItem {
    var type: ChecklistItemType = ChecklistItemType.checklist
    var color: ChecklistItemColor = ChecklistItemColor.red
    var sortIndex: Double = ChecklistsData.SORT_INDEX_SPACING

    var showCompleted: Bool = false

    @Relationship(
        deleteRule: .cascade,
        inverse: \ChecklistItem.parent
    )
    var items: [ChecklistItem]?

    var parent: ChecklistItem?

    init(
        title: String = "",
        type: ChecklistItemType = .checklist,
        color: ChecklistItemColor = .red,
        sortIndex: Double = ChecklistsData.SORT_INDEX_SPACING,
        parent: ChecklistItem? = nil
    ) {
        super.init()
        self.title = title
        self.type = type
        self.color = color
        self.sortIndex = sortIndex
        self.parent = parent
    }
}
