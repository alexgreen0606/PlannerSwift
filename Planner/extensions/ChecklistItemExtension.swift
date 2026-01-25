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
    
}
