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
    var month: Int? = nil
    var day: Int? = nil
    var year: Int? = nil

    var financeVariantRawValue: String = ChecklistItemFinanceVariant.none
        .rawValue

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
        financeVariant = draft.financeVariant
        notes = draft.notes.trimmed
        month = draft.month
        day = draft.day
        year = draft.year
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
        financeVariant = source.financeVariant
        notes = source.notes.trimmed
        month = source.month
        day = source.day
        year = source.year
        hideToggles = source.hideToggles
        height = source.height
        sortIndex = source.sortIndex
        showCompleted = source.showCompleted

        // Form helpers:

        valueInt = NSDecimalNumber(decimal: abs(source.value) * 100).intValue
        valueSign = source.value < 0 ? -1 : 1
    }

    // MARK: Sync draft.
    @MainActor
    func syncDraft() {
        guard let editor else { return }

        editor.draft.title = title
        editor.draft.type = type
        editor.draft.color = color
        editor.draft.value = value
        editor.draft.financeVariantRawValue = financeVariantRawValue
        editor.draft.notes = notes.trimmed
        editor.draft.month = month
        editor.draft.day = day
        editor.draft.year = year
        editor.draft.hideToggles = hideToggles
        editor.draft.height = height
    }
}
