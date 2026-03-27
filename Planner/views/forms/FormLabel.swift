//
//  FormLabel.swift
//  Planner
//
//  Created by Alex Green on 3/25/26.
//

import SwiftUI

// Clean

struct FormLabelView: View {
    private let systemImageName: String
    private let label: String
    private let value: String
    private let detail: String?
    private let color: Color?
    private let onTap: (() -> Void)?

    init(
        systemImageName: String,
        label: String = "",
        value: String,
        detail: String? = nil,
        color: Color? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.systemImageName = systemImageName
        self.label = label
        self.value = value
        self.color = color
        self.detail = detail
        self.onTap = onTap
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    var body: some View {
        let row = HStack {
            Image(systemName: systemImageName)
            Text(label)
            Spacer()
            VStack(alignment: .trailing) {
                ActionTextView(value, color: color)
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
