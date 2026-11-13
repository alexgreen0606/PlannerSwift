//
//  SearchBar.swift
//  Planner
//
//  Created by Alex Green on 11/12/26.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let placeholder: String

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        TextField(
            placeholder,
            text: $text
        )
        .focused(isFocused)
        .submitLabel(.search)
        .safeAreaInset(edge: .leading) {
            Image(systemName: "magnifyingglass")
        }
        .safeAreaInset(edge: .trailing) {
            if isFocused.wrappedValue {
                Image(systemName: "xmark.circle.fill")
                    .contentShape(Rectangle())
                    .onTapGesture {
                        text = ""
                    }
            }
        }
        .tint(accentColor.swiftUiColor)
        .padding()
        .glassEffect(.regular.interactive())
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused.wrappedValue = true
        }
    }
}
