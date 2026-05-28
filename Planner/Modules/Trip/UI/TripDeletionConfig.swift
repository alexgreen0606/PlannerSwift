//
//  TripDeletionConfig.swift
//  Planner
//
//  Created by Alex Green on 4/19/26.
//

func deleteTripConfig(
    trip: Trip,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title: "Delete this trip?",
        message: {
            var message =
                "Events won't be deleted. \(UI.GENERIC_DELETE_WARNING)"

            if trip.location != nil {
                message = "Planner locations will default to your home location. \(message)"
            }

            return message
        }(),
        actions: [
            ConfirmationAction(
                title: "Delete Trip",
                handler: delete
            ),
        ]
    )
}
