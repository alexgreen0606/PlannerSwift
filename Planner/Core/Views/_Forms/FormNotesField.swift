//
//  FormNotesField.swift
//  Planner
//
//  Created by Alex Green on 11/10/26.
//

import SwiftUI

struct FormNotesFieldView: View {
    @Binding var notes: String
    var isFocused: FocusState<Bool>.Binding

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $notes)
                .focused(isFocused)
                .scrollContentBackground(.hidden)

            if notes.trimmed.isEmpty {
                Text("Notes")
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 5)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 200)
    }
}
