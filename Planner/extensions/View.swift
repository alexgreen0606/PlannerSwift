//
//  View.swift
//  Planner
//
//  Created by Alex Green on 12/26/25.
//

import SwiftUI

extension View {
    
    func discreetListItem() -> some View {
        self
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
    }
    
}
