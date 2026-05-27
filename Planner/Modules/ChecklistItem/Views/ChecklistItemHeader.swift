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
    
    private var isRootFolder: Bool {
        item.parent == nil
    }

    private var width: CGFloat {
        if item.type == .folder {
            if isRootFolder {
                return 250
            }
            return 200
        }
        return 250
    }

    // MARK: - Body

    var body: some ToolbarContent {
        if !listEngine.isSelectMode {
            ToolbarItem(placement: .topBarLeading) {
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
                .padding(.leading, isRootFolder ? 0 : -8)
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }
}
