////
////  scrollToEvent.swift
////  Planner
////
////  Created by Alex Green on 2/26/26.
////
//
//private func attemptScrollToEvent(
//    scrollProxy: ScrollViewProxy
//) {
//    guard let pending = pendingScroll, pending.isScrollable else {
//        return
//    }
//
//    let targetEvent: PlannerEvent? = {
//        if let plannerId = pending.plannerId {
//            return sortedOpenPlans.first(where: { $0.stableId == plannerId }
//            )
//        }
//
//        if let calendarId = pending.calendarId {
//            return sortedOpenPlans.first(
//                where: {
//                    $0.calendarEvent?.calendarItemExternalIdentifier
//                        == calendarId
//                }
//            )
//        }
//
//        return nil
//    }()
//
//    guard
//        let event = targetEvent,
//        let targetSortDate = pending.targetSortDate,
//        event.sortDate == targetSortDate
//    else {
//        // List not ready yet. Wait for next change.
//        print("List not ready for scroll. Skipping.")
//        return
//    }
//
//    DispatchQueue.main.async {
//        withAnimation {
//            scrollProxy.scrollTo(event.stableId, anchor: .center)
//        }
//    }
//
//    pendingScroll = nil
//}
