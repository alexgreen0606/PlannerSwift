//
//  ListItemDetails.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

protocol ListItemDetails: PersistentModel {
    var stableId: UUID { get set }
    var title: String { get set }
    var notes: String { get set }
    var height: CGFloat { get set }
    var draft: Self? { get set }
    
    // Updates the draft to match this item.
    func syncDraft()
    
    // Updates this item to match its draft.
    func commitDraft()

    init(draftOf item: Self)
}
