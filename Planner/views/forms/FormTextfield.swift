//
//  FormTitleField.swift
//  Planner
//
//  Created by Alex Green on 3/26/26.
//

import SwiftUI
import SwiftUIIntrospect

// Clean

struct FormTitleFieldView: View {
    @Binding var text: String
    @Binding var hasAutoFocused: Bool  // Unstable if stored in this view. Must be stored in the parent.
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        Section {
            TextField("Title", text: $text)
                .introspect(.textField, on: .iOS(.v26)) { textfield in
                    if !hasAutoFocused, text.isEmpty {
                        textfield.becomeFirstResponder()
                    }
                    hasAutoFocused = true
                }
                .focused(isFocused)

                // Increase the focusable area of the field.
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused.wrappedValue = true
                }
        }
        .listSectionMargins(.top, 16)
    }
}
