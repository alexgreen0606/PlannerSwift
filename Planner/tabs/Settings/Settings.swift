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
    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .system
    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue
    @AppStorage("showListSeparators") private var showListSeparators: Bool =
        true
    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    
                    Picker("Accent Color", selection: $accentColor) {
                        ForEach(AccentColor.allCases, id: \.self) {
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
                        .tint(accentColor.swiftUIColor)
                    
                } header: {
                    Text("Appearance")
                }
                .listSectionMargins(.bottom, 0)
                
                Picker("App Theme", selection: $appColorScheme) {
                    ForEach(AppColorScheme.allCases, id: \.rawValue) {
                        scheme in
                        Text(scheme.rawValue.capitalized)
                            .tag(scheme)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listSectionMargins(.all, 0)

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
                .listSectionMargins(.top, 0)
                
            }
            .navigationTitle("Settings")
        }
    }

}
