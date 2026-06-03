//
//  SheetTitle.swift
//  Planner
//
//  Created by Alex Green on 6/2/26.
//

import SwiftUI

struct SheetTitle: View {
    let title: LocalizedStringKey
    
    init(_ title: LocalizedStringKey) {
        self.title = title
    }

    // MARK: - Body

    // TODO: use in transfer form or wherever it is
    var body: some View {
        Text(title)
            .font(.system(size: 17, weight: .heavy, design: .rounded))
            .padding(.top, 29)
    }
}
