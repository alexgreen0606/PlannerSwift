//
//  ChecklistItem.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

// Clean

@available(iOS 26.0, *)
@Model
class ChecklistItem: ListItem {
    var type: ChecklistItemType
    var color: ChecklistItemColor
    var showCompleted: Bool = false

    @Relationship(
        deleteRule: .cascade,
        inverse: \ChecklistItem.parent
    )
    var items = [ChecklistItem]()

    var parent: ChecklistItem?

    init(
        type: ChecklistItemType = .checklist,
        title: String = "",
        color: ChecklistItemColor = .red,
        sortIndex: Double,
        parent: ChecklistItem? = nil
    ) {
        self.type = type
        self.color = color
        self.parent = parent

        super.init(sortIndex: sortIndex)
        self.title = title
    }
}
