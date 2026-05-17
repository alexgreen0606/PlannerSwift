//
//  ChecklistItem.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

@available(iOS 26.0, *)
@Model
class ChecklistItem: ListItem {
    var type: ChecklistItemType = ChecklistItemType.checklist
    var color: ChecklistItemColor = ChecklistItemColor.red
    var showCompleted: Bool = false
    var sortIndex: Double = 10.0

    @Relationship(
        deleteRule: .cascade,
        inverse: \ChecklistItem.parent
    )
    var items: [ChecklistItem]?

    var parent: ChecklistItem?

    init(
        type: ChecklistItemType = .checklist,
        title: String = "",
        color: ChecklistItemColor = .red,
        sortIndex: Double,
        parent: ChecklistItem? = nil
    ) {
        super.init()
        self.type = type
        self.color = color
        self.parent = parent
        self.title = title
    }
}
