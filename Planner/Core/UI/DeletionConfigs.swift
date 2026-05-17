//
//  DeletionConfigs.swift
//  Planner
//
//  Created by Alex Green on 4/17/26.
//

let genericDeleteWarning: String = "This can't be undone."

// MARK: - Confirmation Rules:

// MARK: Titles

// 1. Single Delete: Use item title UNLESS in a form. Then use "this".
//      FORM: "Delete this checklist?" | NOT FORM: "Delete checklist "Shopping"?"

// 2. Bulk Delete Selections: Use item count.
//      "Delete 4 checklists?"

// 3. Bulk Delete Category: Use type of items always pluralized combined with parent title.
//      "Delete completed items from April 17th?"

// MARK: Message

// 1. Single Delete: Only show specifics if it pertains to the item.

// 2. Bulk Delete Selections: Only show specifics that pertain to the selections.

// 3. Bulk Delete Category: Always show specifics.

// MARK: Button

// 1. Single Delete: Never use the item title. Just the type.
//      "Delete Checklist"

// 2. Bulk Delete Selections: Use item count.

// 3. Bulk Delete Category: Use item count.
