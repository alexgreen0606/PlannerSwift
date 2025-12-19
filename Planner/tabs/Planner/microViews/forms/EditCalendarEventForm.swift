//
//  EditCalendarEventView.swift
//  Planner
//
//  Created by Alex Green on 12/17/25.
//

import EventKit
import EventKitUI
import SwiftUI

struct EditCalendarEventView: UIViewControllerRepresentable {
    let event: EKEvent
    let eventStore: EKEventStore
    let onComplete: (EKEventEditViewAction, EKEvent?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let vc = EKEventEditViewController()
        vc.eventStore = eventStore
        vc.event = event
        vc.editViewDelegate = context.coordinator

        return vc
    }

    func updateUIViewController(
        _ uiViewController: EKEventEditViewController,
        context: Context
    ) {}

    class Coordinator: NSObject, EKEventEditViewDelegate {
        let onComplete: (EKEventEditViewAction, EKEvent?) -> Void

        init(onComplete: @escaping (EKEventEditViewAction, EKEvent?) -> Void) {
            self.onComplete = onComplete
        }

        func eventEditViewController(
            _ controller: EKEventEditViewController,
            didCompleteWith action: EKEventEditViewAction
        ) {
            onComplete(action, controller.event)
        }
    }
}
