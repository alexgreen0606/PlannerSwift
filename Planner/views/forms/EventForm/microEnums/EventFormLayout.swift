//
//  EventFormLayout.swift
//  Planner
//
//  Created by Alex Green on 3/25/26.
//

import SwiftUI

// Clean

// TODO: maybe remove this if you stick to fixed-detent event forms
enum EventFormLayout {
    static let SMALL_DETENT: PresentationDetent = .height(430)
    static let MEDIUM_DETENT: PresentationDetent = .height(715)
    static let MEDIUM_LARGE_DETENT: PresentationDetent = .height(820)
    static let LARGE_DETENT: PresentationDetent = .large
}
