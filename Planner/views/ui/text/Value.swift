//
//  Value.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import SwiftUI

struct ValueView: View {
    private let title: String
    private let color: Color?
    private let scale: Double

    init(_ title: String, color: Color? = nil, scale: Double? = nil) {
        self.title = title
        self.color = color
        self.scale = scale ?? 1
    }
    
    private var fontSize: CGFloat {
        14 * scale
    }

    var body: some View {
        Text(title)
            .font(.system(size: fontSize, weight: .regular))
            .foregroundColor(color ?? Color.label)
    }
}
