//
//  planner.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftData
import SwiftDate
import SwiftUI
import EventKit

extension ModelContext {
    
    @MainActor
    func ensurePlanner(
        planners: [Planner],
        datestamp: String
    ) {
        if planners.first != nil {
            return
        }

        let planner = Planner(datestamp: datestamp, location: nil)
        insert(planner)

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to create Planner for \(datestamp): \(error)"
            )
        }
    }
    
    @MainActor
    func loadPlanner(
        for datestamp: String
    ) -> Planner {

        let descriptor = FetchDescriptor<Planner>(
            predicate: #Predicate<Planner> { planner in
                planner.datestamp == datestamp
            }
        )

        do {
            let planners = try fetch(descriptor)

            guard let planner = planners.first else {
                return Planner(datestamp: datestamp, location: nil)
            }

            return planner
        } catch {
            let newPlanner = Planner(datestamp: datestamp, location: nil)
            
            insert(newPlanner)
            
            do {
                try save()
            } catch {
                print("ERROR planner.loadPlanner: \(error)")
            }
            
            return newPlanner
        }
    }
    
    @MainActor
    func updateLocation(
        for planner: Planner,
        location: Location?,
    ) {
        
        planner.location = location

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR planner.updateLocation: \(error)"
            )
        }
    }
    
    @MainActor
    func deleteOldPlanners(
        from planners: [Planner],
        before cutoffDate: Date
    ) {

        let cutoffDatestamp = cutoffDate.toFormat("yyyy-MM-dd")

        for planner in planners {
            if planner.datestamp < cutoffDatestamp {
                print("Deleting planner: \(planner.datestamp)")
                delete(planner)
            }
        }

        // Sepcial case: do NOT save the context here. This will be done in the parent
        // function that called this.
    }
    
}
