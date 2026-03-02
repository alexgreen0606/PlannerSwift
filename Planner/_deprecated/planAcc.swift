//
//  planAcc.swift
//  Planner
//
//  Created by Alex Green on 3/2/26.
//


// NOTE: May want to add this in futue. For now it is too bulky and not useful enough to justify.
//        .tabViewBottomAccessory {
//
//            PlannerAccessoryView(
//                todaystamp: todaystampWatcher.todaystamp,
//                animation: todayPlannerCoverAnimation
//            ) {
//                isTodayPlannerOpen.toggle()
//            }
//
//        }
//        .fullScreenCover(isPresented: $isTodayPlannerOpen) {
//            NavigationStack {
//                PlannerView(
//                    datestamp: todaystampWatcher.todaystamp
//                ) {
//                    isTodayPlannerOpen.toggle()
//                }
//            }
//            .environmentObject(todayPlannerManager)
//            .navigationTransition(
//                .zoom(
//                    sourceID: "PLANNER_ACCESSORY",
//                    in: todayPlannerCoverAnimation
//                )
//            )
//        }
