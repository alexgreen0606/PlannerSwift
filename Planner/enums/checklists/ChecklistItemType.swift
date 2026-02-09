//
//  ChecklistItemType.swift
//  Planner
//
//  Created by Alex Green on 1/20/26.
//

enum ChecklistItemType: String, Codable {
    case folder
    case checklist
    case item

    var iconName: String {
        switch self {
        case .folder: return "folder.fill"
        case .checklist: return "list.bullet"
        case .item: return "exclamationmark"
        }
    }

    var capitalizedLabel: String {
        switch self {
        case .folder: return "Folder"
        case .checklist: return "Checklist"
        case .item: return "Item"
        }
    }
}
