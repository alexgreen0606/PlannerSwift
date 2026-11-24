//
//  ViewCalendarEventForm.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import EventKitUI
import SwiftUI

struct ViewCalendarEventFormView: UIViewControllerRepresentable {
    let ekEvent: EKEvent

    func makeUIViewController(context _: Context) -> UINavigationController {
        let vc = EKEventViewController()

        vc.event = ekEvent

        let nav = UINavigationController(rootViewController: vc)
        nav.setNavigationBarHidden(true, animated: false)
        nav.setToolbarHidden(true, animated: false)

        return nav
    }

    func updateUIViewController(
        _: UINavigationController,
        context _: Context
    ) {}
}
