//
//  ViewCalendarEventForm.swift
//  Planner
//
//  Created by Alex Green on 12/17/25.
//

import EventKit
import EventKitUI
import SwiftUI

// Clean

struct ViewCalendarEventFormView: UIViewControllerRepresentable {
    let event: EKEvent

    func makeUIViewController(context _: Context) -> UINavigationController {
        let vc = EKEventViewController()

        vc.event = event
        vc.additionalSafeAreaInsets.top = 16

        let nav = UINavigationController(rootViewController: vc)
        nav.setNavigationBarHidden(true, animated: false)

        return nav
    }

    func updateUIViewController(
        _: UINavigationController,
        context _: Context
    ) {}
}
