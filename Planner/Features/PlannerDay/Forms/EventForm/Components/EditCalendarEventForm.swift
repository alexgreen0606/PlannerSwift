//
//  EditCalendarEventForm.swift
//  Planner
//
//  Created by Alex Green on 12/17/25.
//

import EventKit
import EventKitUI
import SwiftUI

// Clean

struct EditCalendarEventFormView: UIViewControllerRepresentable {
    let event: EKEvent
    let ekEventStore: EKEventStore
    let onSave: (EKEventEditViewAction, EKEvent?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSave: onSave)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let vc = EKEventEditViewController()

        vc.eventStore = ekEventStore
        vc.event = event
        vc.editViewDelegate = context.coordinator
        vc.additionalSafeAreaInsets.bottom = 30

        return vc
    }

    func updateUIViewController(
        _: EKEventEditViewController,
        context _: Context
    ) {}

    class Coordinator: NSObject, EKEventEditViewDelegate {
        let onSave: (EKEventEditViewAction, EKEvent?) -> Void

        init(onSave: @escaping (EKEventEditViewAction, EKEvent?) -> Void) {
            self.onSave = onSave
        }

        func eventEditViewController(
            _ controller: EKEventEditViewController,
            didCompleteWith action: EKEventEditViewAction
        ) {
            onSave(action, controller.event)
        }
    }
}
