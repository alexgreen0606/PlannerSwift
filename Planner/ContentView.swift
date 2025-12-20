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
    @State var calendarEventStore = CalendarEventStore.shared

    @AppStorage("lastCleanedDatestamp") var lastCleanedDatestamp: String = ""
    @AppStorage("themeColor") var themeColor: ThemeColorOption =
        ThemeColorOption.blue

    @State private var searchText: String = ""

    let plannerManager = ListManager()
    
    @State private var isPlannerOpen: Bool = false

    @Namespace private var animation

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
        TabView(selection: $navigationManager.selectedTab) {
            Tab(value: .checklists) {
                ChecklistsTabView()
            } label: {
                Label(
                    "",
                    systemImage: "list.bullet"
                )
            }

            Tab(value: .recurring) {
            } label: {
                Label("", systemImage: "repeat")
            }

            Tab(value: .search, role: .search) {
                NavigationStack {
                    PlannerSelectView(isPlannerOpen: $isPlannerOpen)
                }
            } label: {
                Label(
                    "",
                    systemImage: "calendar"
                )
            }

        }
        .searchable(text: $searchText)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            HStack(spacing: 8) {
                Image(
                    systemName: todaystampManager.todaystamp.calendarSymbolName
                )
                .foregroundColor(themeColor.swiftUIColor)
                .imageScale(.large)

                VStack {
                    Text(todaystampManager.todaystamp.date?.dayName ?? "")
                }
                .frame(maxHeight: .infinity, alignment: .top)

                Spacer()
            }
            .padding(16)
            .contentShape(Rectangle())
            .onTapGesture {
                isPlannerOpen.toggle()
            }
            .matchedTransitionSource(id: "ACCESSORY", in: animation)
        }
        .fullScreenCover(isPresented: $isPlannerOpen) {
            NavigationStack {
                PlannerView(datestamp: navigationManager.plannerDatestamp, isPlannerOpen: $isPlannerOpen)
            }
            .environmentObject(plannerManager)
            .navigationTransition(
                .zoom(sourceID: "ACCESSORY", in: animation)
            )
        }
    }
}

#Preview {
    ContentView()
}
