//
//  FormLabel.swift
//  Planner
//
//  Created by Alex Green on 3/25/26.
//

import SwiftUI

struct FormLabelView<CustomValue: View>: View {
    private let systemImageName: String
    private let label: String
    private let value: String?
    private let customValue: CustomValue?
    private let detail: LocalizedStringKey?
    private let onTap: (() -> Void)?

    // MARK: Standard
    init(
        systemImageName: String,
        label: String = "",
        value: String,
        detail: LocalizedStringKey? = nil,
        color: Color? = nil,
        onTap: (() -> Void)? = nil
    ) where CustomValue == EmptyView {
        self.customValue = nil

        self.systemImageName = systemImageName
        self.label = label
        self.value = value
        self.detail = detail
        self.onTap = onTap

        customColor = color
    }

    // MARK: Custom Value View
    init(
        systemImageName: String,
        label: String = "",
        value: CustomValue,
        detail: LocalizedStringKey? = nil,
        color: Color? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.value = nil

        self.systemImageName = systemImageName
        self.label = label
        self.customValue = value
        self.detail = detail
        self.onTap = onTap

        customColor = color
    }

    private let customColor: Color?

    // MARK: - Body

    var body: some View {
        let row = HStack {
            Image(systemName: systemImageName)
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
            VStack(alignment: .trailing) {
                if let customValue {
                    customValue
                } else if let value {
                    ActionText(value, color: customColor)
                }
                if let detail {
                    Text(detail)
                        .font(
                            .system(size: 11, weight: .bold, design: .rounded)
                        )
                        .foregroundStyle(Color.secondary)
                }
            }
        }

        if let onTap {
            row.contentShape(Rectangle()).onTapGesture(perform: onTap)
        } else {
            row
        }
    }
}
