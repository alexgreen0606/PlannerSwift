//
//  IconSelector.swift
//  Planner
//
//  Created by Alex Green on 3/19/26.
//

import SwiftUI

// Clean

struct IconSelectorView: View {
    let selectedIconConfig: IconConfig
    let options: [IconConfig]
    let numColumns: Int
    let isLargeIcon: Bool
    let onTap: (IconConfig) -> Void

    init(
        selectedIconConfig: IconConfig,
        options: [IconConfig],
        numColumns: Int,
        isLargeIcon: Bool = false,
        onTap: @escaping (IconConfig) -> Void
    ) {
        self.selectedIconConfig = selectedIconConfig
        self.options = options
        self.numColumns = numColumns
        self.isLargeIcon = isLargeIcon
        self.onTap = onTap
    }

    @State private var isPresented = false

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: 32),
            count: numColumns
        )
    }

    var body: some View {
        Image(systemName: selectedIconConfig.name)
            .foregroundStyle(
                selectedIconConfig.primaryColor,
                selectedIconConfig.secondaryColor
            )
            .imageScale(isLargeIcon ? .large : .medium)
            .contentShape(Rectangle())
            .onTapGesture {
                isPresented = true
            }
            .popover(isPresented: $isPresented) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 32) {
                        ForEach(options, id: \.id) { config in
                            Image(systemName: config.name)
                                .foregroundStyle(
                                    config.primaryColor,
                                    config.secondaryColor
                                )
                                .imageScale(.large)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onTap(config)
                                    isPresented = false
                                }
                        }
                    }
                    .padding(.all, 32)
                }
                .presentationCompactAdaptation(.popover)
            }
    }
}
