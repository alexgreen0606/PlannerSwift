//
//  EnvironmentValues+.swift
//  Planner
//
//  Created by Alex Green on 5/25/26.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var showToast: (Toast) -> Void = { _ in }
}
