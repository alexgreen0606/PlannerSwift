//
//  ViewCalendarEventForm.swift
//  Planner
//
//  Created by Alex Green on 12/17/25.
//

import EventKit
import EventKitUI
import SwiftUI

struct ViewCalendarEventFormView: UIViewControllerRepresentable {
    let plannerEvent: PlannerEvent
    let ekEventStore: EKEventStore

    func makeUIViewController(context _: Context) -> UINavigationController {
        guard let event = ekEventStore.getEkEvent(for: plannerEvent)
        else {
            // Show empty view in case of load error.
            let vc = UIViewController()
            return UINavigationController(rootViewController: vc)
        }

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
