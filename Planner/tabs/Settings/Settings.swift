//
//  Settings.swift
//  Planner
//
//  Created by Alex Green on 1/4/26.
//

import Combine
import EventKit
import SwiftData
import SwiftUI

struct SettingsView: View {
    @AppStorage("themeColor") var themeColor: ThemeColor =
        ThemeColor.blue
    @AppStorage("showListSeparators") private var showListSeparators: Bool =
        true
    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("App Theme", selection: $keepPastPlansDuration) {
                        // TODO:

                        // System

                        // Light

                        // Dark
                    }
                    .pickerStyle(.menu)

                    Picker("Accent Color", selection: $themeColor) {
                        ForEach(ThemeColor.allCases, id: \.self) {
                            option in
                            Image(systemName: "circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(option.swiftUIColor)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker(
                        "Completed Item Fade Duration",
                        selection: $keepPastPlansDuration
                    ) {
                        // TODO: 2 sec, 3sec, 6sec, Instant
                    }
                    .pickerStyle(.menu)

                    Toggle("Show List Separators", isOn: $showListSeparators)
                        .tint(themeColor.swiftUIColor)
                } header: {
                    Text("Appearance")
                }

                Section {
                    Picker("Keep Past Plans", selection: $keepPastPlansDuration)
                    {
                        ForEach(KeepPastPlansDuration.allCases, id: \.self) {
                            option in
                            Text(option.label)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker(
                        "Keep Canceled Plans",
                        selection: $keepPastPlansDuration
                    ) {
                        // TODO
                    }
                    .pickerStyle(.menu)

                    Picker(
                        "Show End Events",
                        selection: $keepPastPlansDuration
                    ) {
                        // TODO: For multi-day only, always
                    }
                    .pickerStyle(.menu)

                    NavigationLink("Calendars") {
                        CalendarsView()
                    }
                } header: {
                    Text("Planner")
                }
            }
            .navigationTitle("Settings")
        }
    }

}
