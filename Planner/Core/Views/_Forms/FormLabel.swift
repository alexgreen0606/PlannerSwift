//
//  FormLabel.swift
//  Planner
//
//  Created by Alex Green on 3/25/26.
//

import SwiftUI

struct FormLabelView<CustomValue: View>: View {
    private let iconConfig: IconConfig?
    private let label: String
    private let value: String?
    private let customValue: CustomValue?
    private let detail: LocalizedStringKey?
    private let onTap: (() -> Void)?
    
    // MARK: Standard
    init(
        systemImageName: String? = nil,
        label: String = "",
        value: String,
        detail: LocalizedStringKey? = nil,
        color: Color? = nil,
        onTap: (() -> Void)? = nil
    ) where CustomValue == EmptyView {
        self.customValue = nil

        self.iconConfig = systemImageName != nil ? IconConfig(
            name: systemImageName!,
            primaryColor: Color.label,
            secondaryColor: Color.label
        ) : nil
        self.label = label
        self.value = value
        self.detail = detail
        self.onTap = onTap

        customColor = color
    }

    // MARK: Custom Icon
    init(
        iconConfig: IconConfig? = nil,
        label: String = "",
        value: String,
        detail: LocalizedStringKey? = nil,
        color: Color? = nil,
        onTap: (() -> Void)? = nil
    ) where CustomValue == EmptyView {
        self.customValue = nil

        self.iconConfig = iconConfig
        self.label = label
        self.value = value
        self.detail = detail
        self.onTap = onTap

        customColor = color
    }

    // MARK: Custom Value View
    init(
        systemImageName: String? = nil,
        label: String = "",
        value: CustomValue,
        detail: LocalizedStringKey? = nil,
        color: Color? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.value = nil

        self.iconConfig = systemImageName != nil ? IconConfig(
            name: systemImageName!,
            primaryColor: Color.label,
            secondaryColor: Color.label
        ) : nil
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
            if let iconConfig {
                Icon(iconConfig)
            }
            
            Text(label)
            
            Spacer()
            
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
