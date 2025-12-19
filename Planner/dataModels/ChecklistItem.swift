//
//  FolderItem.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

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
}

enum ColorOption: String, Codable, CaseIterable {
    case red
    case orange
    case yellow
    case green
    case cyan
    case indigo
    case purple
    case brown
    case label

    var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .cyan: return .cyan
        case .indigo: return .indigo
        case .purple: return .purple
        case .brown: return .brown
        case .label: return Color(uiColor: .label)
        }
    }
    
    var uIColor: UIColor {
        switch self {
        case .red: return .systemRed
        case .orange: return .systemOrange
        case .yellow: return .systemYellow
        case .green: return .systemGreen
        case .cyan: return .systemCyan
        case .indigo: return .systemIndigo
        case .purple: return .systemPurple
        case .brown: return .systemBrown
        case .label: return .label
        }
    }
}

@available(iOS 26.0, *)
@Model
class ChecklistItem: ListItem {
    var type: ChecklistItemType
    var color: ColorOption

    @Relationship(deleteRule: .cascade)
    var items = [ChecklistItem]()
    
    @Relationship(inverse: \ChecklistItem.items)
    var parent: ChecklistItem?

    init(type: ChecklistItemType = .checklist, title: String = "", color: ColorOption = .red, sortIndex: Double, parent: ChecklistItem? = nil) {
        self.type = type
        self.color = color
        self.parent = parent
        
        super.init(sortIndex: sortIndex)
        self.title = title
        
        parent?.items.append(self)
    }
}
