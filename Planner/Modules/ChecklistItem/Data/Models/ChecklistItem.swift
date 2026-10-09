//
//  ChecklistItem.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

@Model
final class ChecklistItem: ListItemDetails {

    var stableId: UUID = UUID()

    var title: String = ""
    var type: ChecklistItemType = ChecklistItemType.checklist
    var color: ChecklistItemColor = ChecklistItemColor.cyan
    var isCompleted: Bool = false

    /// Should only be non-zero for ChecklistItemType.item
    var value: Decimal = 0.00
    
    var notes: String = ""

    var variants: [ChecklistItemVariant] = []

    var height: CGFloat = 0

    var sortIndex: Double = ChecklistsData.SORT_INDEX_SPACING

    var showCompleted: Bool = false
    
    var hideToggles: Bool = false

    // MARK: Parent
    var parent: ChecklistItem?

    // MARK: Children
    @Relationship(
        deleteRule: .cascade,
        inverse: \ChecklistItem.parent
    )
    var items: [ChecklistItem]?

    /// Used for form currency fields.
    @Transient
    var valueInt: Int = 0

    /// Used for form currency fields. (1 is positive, -1 is negative)
    @Transient
    var valueSign: Int = 1

    @Transient
    var editor: EditorSession<ChecklistItem>?

    init(
        title: String = "",
        type: ChecklistItemType = .checklist,
        sortIndex: Double = ChecklistsData.SORT_INDEX_SPACING,
        parent: ChecklistItem? = nil
    ) {
        self.title = title
        self.type = type
        self.sortIndex = sortIndex
        self.parent = parent

        parent?.items.safeAppend(self)
    }

    // MARK: Create from a draft.
    init(
        draft: ChecklistItem,
        sortIndex: Double,
        parent: ChecklistItem
    ) {
        title = draft.title
        type = draft.type
        color = draft.color
        value = draft.value
        variants = draft.variants
        notes = draft.notes.trimmed
        hideToggles = draft.hideToggles

        self.sortIndex = sortIndex
        self.parent = parent

        parent.items.safeAppend(self)
    }

    // MARK: Create a draft.
    required init(draftOf source: ChecklistItem) {
        stableId = source.stableId
        title = source.title
        type = source.type
        color = source.color
        isCompleted = source.isCompleted
        value = source.value
        variants = source.variants
        notes = source.notes.trimmed
        hideToggles = source.hideToggles
        height = source.height
        sortIndex = source.sortIndex
        showCompleted = source.showCompleted

        // Form helpers:

        valueInt = NSDecimalNumber(decimal: abs(source.value) * 100).intValue
        valueSign = source.value < 0 ? -1 : 1
    }
}
