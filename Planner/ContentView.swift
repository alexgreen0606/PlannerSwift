//
//  ContentView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftDate
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var todaystampManager: TodaystampManager
    
    @State var navigationManager = NavigationManager.shared

    // Set the styles for all of the tab headers.
    init() {
        // Large Title
        if var descriptor = UIFontDescriptor.preferredFontDescriptor(
            withTextStyle: .largeTitle
        )
        .withDesign(.rounded) {
            // heavy weight
            descriptor = descriptor.addingAttributes([
                .traits: [
                    UIFontDescriptor.TraitKey.weight: UIFont.Weight.heavy
                ]
            ])

            // font size
            let customSize: CGFloat = 28
            let font = UIFont(descriptor: descriptor, size: customSize)
            UINavigationBar.appearance().largeTitleTextAttributes = [
                .font: font
            ]
        }

        // Inline Title
        if var descriptor = UIFontDescriptor.preferredFontDescriptor(
            withTextStyle: .headline
        )
        .withDesign(.rounded) {
            // heavy weight
            descriptor = descriptor.addingAttributes([
                .traits: [
                    UIFontDescriptor.TraitKey.weight: UIFont.Weight.heavy
                ]
            ])

            // font size
            let customSize: CGFloat = 22
            let font = UIFont(descriptor: descriptor, size: customSize)
            UINavigationBar.appearance().titleTextAttributes = [
                .font: font
            ]
        }
    }

    var body: some View {
        TabView {
            Tab("", systemImage: todaystampManager.todaystamp.toCalendarSymbolName()) {
                PlannerTabView()
            }
            Tab("", systemImage: "list.bullet") {
                NavigationStack {
                    VStack{}
                        .navigationTitle("Checklists")
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("More", systemImage: "ellipsis") {

                                }
                            }
                        }
                    }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
}
