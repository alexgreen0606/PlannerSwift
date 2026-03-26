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
    private let onTap: (() -> Void)?

    init(
        systemImageName: String,
        label: String = "",
        value: String,
        onTap: (() -> Void)? = nil
    ) {
        self.systemImageName = systemImageName
        self.label = label
        self.value = value
        self.onTap = onTap
        self.accentColor = accentColor
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    var body: some View {
        let row = HStack {
            Image(systemName: systemImageName)
            Text(label)
            Spacer()
            ActionTextView(value)
        }

        if let onTap {
            row.contentShape(Rectangle()).onTapGesture(perform: onTap)
        } else {
            row
        }
    }
}
