//
//  Design.swift
//  Planner
//
//  Created by Alex Green on 5/18/26.
//

// Modifier order:
// View
// Important (ID, animation)
// View-specific
// Style(Style, Font, Color, Opacity),
// Layout(Frame, Padding),
// Safe Area
// Overlay
// Toolbar
// Other(Custom),
// Transition,
// Tap
// Task
// onChange

// Animation goes where needed (first modifier on that view)

// TO CHECK:
// 1. Always say calendarRecord, plannerEvent, ekEvent, etc instead of just event
// 2. Always put predicates in separate folders
// 3. Use different inits for different cases
// 4. Alkways log errors with a space between file name and function name
// 5. Relationships are always double-set and initialized
// 6. Comments defining vars use 3 slashes


// DOCUMENTATION TO ADD:
// 1. calendarRecords means plannerEvents that represent EKEvents
// 2. routineEventRecords means plannerEvents that represent RoutineEvent
