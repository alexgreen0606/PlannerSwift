//
//  RoutineEventContext.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import EventKit
import Foundation
import SwiftData

@Model
final class RoutineEventContext: EventDetails {

    var stableId: UUID = UUID()

    var title: String = ""
    var notes: String = ""
    var time: Date?

    var height: CGFloat = 0

    var version: Double = 1.0

    // MARK: Children
    @Relationship(
        deleteRule: .cascade,
        inverse: \RoutineEvent.routineEventContext
    )
    var routineEvents: [RoutineEvent]?

    @Transient
    var draft: RoutineEventContext?

    init() {}

    // MARK: Create a draft.
    required init(draftOf source: RoutineEventContext) {
        stableId = source.stableId
        title = source.title
        notes = source.notes
        height = source.height
    }
    
    @MainActor
    func syncDraft() {
        guard let draft else { return }

        draft.title = title
        draft.notes = notes
        draft.time = time
        draft.height = height
    }
    
    @MainActor
    func commitDraft() {
        guard let draft else { return }

        title = draft.title.trimmed
        notes = draft.notes.trimmed
        time = draft.time
        height = draft.height
    }
}
