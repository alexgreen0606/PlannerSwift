//
//  ChecklistItemSheetContext.swift
//  Planner
//
//  Created by Alex Green on 1/20/26.
//

enum ChecklistItemSheetContext: Identifiable {
    case create
    case parent
    case edit(ChecklistItem)

    var id: String {
        switch self {
        case .parent: return "PARENT"
        case .create: return "CREATE"
        case .edit(let item): return String(describing: item.id)
        }
    }
}
