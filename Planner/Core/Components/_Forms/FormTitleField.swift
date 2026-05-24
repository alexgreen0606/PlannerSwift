//
//  FormTitleField.swift
//  Planner
//
//  Created by Alex Green on 3/26/26.
//

import SwiftUI
import SwiftUIIntrospect

struct FormTitleFieldView: View {
    @Binding var text: String
    
    /// Note: Unstable if stored in this view. Must be stored in the parent.
    @Binding var hasAutoFocused: Bool
    
    var isFocused: FocusState<Bool>.Binding
    
    // MARK: - Body

    var body: some View {
        Section {
            TextField("Title", text: $text)
                .focused(isFocused)
                .introspect(.textField, on: .iOS(.v26)) { textfield in
                    if !hasAutoFocused, text.isEmpty {
                        textfield.becomeFirstResponder()
                    }
                    hasAutoFocused = true
                }
            
                // MARK: Increase the focusable area of the field.
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused.wrappedValue = true
                }
        }
        .listSectionMargins(.top, 16)
    }
}
