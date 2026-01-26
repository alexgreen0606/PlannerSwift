//
//  ChecklistItemExtension.swift
//  Planner
//
//  Created by Alex Green on 1/24/26.
//

extension ChecklistItem {

    var itemPath: String {
        var components: [String] = []
        var current: ChecklistItem? = self.parent

        while let item = current {
            if !item.title.isEmpty {
                components.append(item.title)
            }
            current = item.parent
        }

        return components.reversed().joined(separator: " / ")
    }
    
    var childrenLabel: String {
        self.type == .checklist ? "items" : "contents"
    }
    
    var deleteConfirmation: String {
        "Delete this entire \(self.type.rawValue)?"
    }
    
    var deleteWarning: String {
        "\(self.items.isEmpty ? "" : "All \(childrenLabel) will be lost. ")This action is irreversible."
    }
    
}
