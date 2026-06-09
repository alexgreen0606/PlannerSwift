//
//  SheetTitle.swift
//  Planner
//
//  Created by Alex Green on 6/2/26.
//

import SwiftUI

// Note: This is an exact mock of the default sheet navigation title.

struct SheetTitle: View {
    let title: LocalizedStringKey

    init(_ title: LocalizedStringKey) {
        self.title = title
    }

    // MARK: - Body

    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .padding(.top, 29)
    }
}
