//
//  SearchInset.swift
//  Planner
//
//  Created by Alex Green on 6/8/26.
//

import SwiftUI

struct SearchInsetView: View {
    let focused: CGFloat
    let blurred: CGFloat

    @Environment(\.isSearching) private var isSearching

    // MARK: - Body

    var body: some View {
        Color.clear.frame(height: isSearching ? focused : blurred)
    }
}
