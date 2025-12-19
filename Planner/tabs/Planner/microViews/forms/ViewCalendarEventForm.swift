//
//  ViewCalendarEventView.swift
//  Planner
//
//  Created by Alex Green on 12/17/25.
//

import EventKit
import EventKitUI
import SwiftUI

struct ViewCalendarEventView: UIViewControllerRepresentable {
    let event: EKEvent

    func makeUIViewController(context: Context) -> UINavigationController {
        let vc = EKEventViewController()
        vc.event = event
        vc.allowsEditing = false
        vc.allowsCalendarPreview = true

        let nav = UINavigationController(rootViewController: vc)
        nav.setNavigationBarHidden(true, animated: false)
        
        vc.additionalSafeAreaInsets.top = 16
        
        // TODO: disable scroll and make background clear for glass effect

        return nav
    }

    func updateUIViewController(
        _ uiViewController: UINavigationController,
        context: Context
    ) {}
}
