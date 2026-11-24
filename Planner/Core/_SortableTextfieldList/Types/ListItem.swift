//
//  ListItem.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import Foundation
import Observation

/// Any row that can be rendered by `SortableTextfieldListView`.
///
/// Conforming types do not need to be SwiftData models. They can be
/// lightweight value types that wrap other data (ex: `PlannerItem` wraps a `PlannerEvent`
/// or an `EKEvent`). Editing happens through a separate `Draft` object owned by `ListEngine`.
protocol ListItem: Identifiable {
    associatedtype Draft: ListItemDraft where Draft.Item == Self

    /// The live title displayed while the row is not being edited.
    var title: String { get }

    var notes: String { get }

    /// When false, tapping the title calls `onAdornmentClick` instead of editing inline.
    var allowsEditing: Bool { get }
}

// TODO: why have this?
extension ListItem {
    var allowsEditing: Bool {
        true
    }
}

/// An in-memory editing buffer for a `ListItem`.
///
/// Drafts are stored by `ListEngine` (keyed by the item's ID) so they survive row re-creation
/// while editing. They must be `@Observable` classes so the row's text field can bind to them.
protocol ListItemDraft: AnyObject, Observable {
    associatedtype Item

    var title: String { get set }
    var height: CGFloat { get set }

    init(item: Item)

    /// Updates this draft to match the item.
    func sync(from item: Item)

    /// Updates the item to match this draft.
    func commit(to item: Item)

    /// Special handler called before creating new items, so that empty-neighbor
    /// checks see the focused item's latest title.
    func commitTitle(to item: Item)
}
