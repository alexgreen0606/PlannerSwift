//
//  ChecklistItemType.swift
//  Planner
//
//  Created by Alex Green on 1/20/26.
//

// Clean

enum ChecklistItemType: String, Codable {
    case folder
    case checklist
    case item

    var systemImageName: String {
        switch self {
        case .folder: return "folder.fill"
        case .checklist: return "list.bullet"
        case .item: return "exclamationmark"
        }
    }
    
}
