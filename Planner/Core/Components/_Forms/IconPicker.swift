//
//  IconPicker.swift
//  Planner
//
//  Created by Alex Green on 3/19/26.
//

import SwiftUI

struct IconPickerView: View {
    private let selectedIconConfig: IconConfig
    // TODO: move this into IconConfig
    private let largeIcon: Bool
    private let options: [IconConfig]
    private let numColumns: Int
    private let onTap: (IconConfig) -> Void

    init(
        selectedIconConfig: IconConfig,
        largeIcon: Bool = false,
        options: [IconConfig],
        numColumns: Int,
        onTap: @escaping (IconConfig) -> Void
    ) {
        self.selectedIconConfig = selectedIconConfig
        self.largeIcon = largeIcon
        self.options = options
        self.numColumns = numColumns
        self.onTap = onTap
    }

    private let SPACING: CGFloat = 32

    @State private var showOptions = false

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: SPACING),
            count: numColumns
        )
    }

    // MARK: - Body

    var body: some View {
        Image(systemName: selectedIconConfig.name)
            .imageScale(largeIcon ? .large : .medium)
            .foregroundStyle(
                selectedIconConfig.primaryColor,
                selectedIconConfig.secondaryColor
            )
            .contentShape(Rectangle())
            .onTapGesture {
                showOptions = true
            }
            .popover(isPresented: $showOptions) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: SPACING) {
                        ForEach(options, id: \.id) { config in
                            Image(systemName: config.name)
                                .imageScale(.large)
                                .foregroundStyle(
                                    config.primaryColor,
                                    config.secondaryColor
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onTap(config)
                                    showOptions = false
                                }
                        }
                    }
                    .padding(SPACING)
                }
                .presentationCompactAdaptation(.popover)
            }
    }
}
