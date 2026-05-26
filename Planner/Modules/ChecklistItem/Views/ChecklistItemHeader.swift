//
//  ChecklistItemHeader.swift
//  Planner
//
//  Created by Alex Green on 5/26/26.
//

import SwiftUI

struct ChecklistItemHeaderView: ToolbarContent {
    let item: ChecklistItem

    @EnvironmentObject private var listEngine: ListEngine<ChecklistItem>

    private var placement: ToolbarItemPlacement {
        if item.type == .folder, item.parent == nil {
            return .topBarLeading
        }
        return .principal
    }

    private var width: CGFloat {
        if item.type == .folder {
            if item.parent == nil {
                return 250
            }
            return 210
        }
        return 260
    }

    // MARK: - Body

    var body: some ToolbarContent {
        if !listEngine.isSelectMode {
            ToolbarItem(placement: placement) {
                HStack {
                    Image(systemName: item.type.systemImageName)
                        .foregroundStyle(item.color.swiftUIColor)

                    Text(item.title)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .frame(width: width, alignment: .leading)
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }
}
