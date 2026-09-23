//
//  HomepageForm.swift
//  Planner
//
//  Created by Alex Green on 9/22/26.
//

import SwiftUI

struct HomepageFormView: View {
    let settings: Settings

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        List {
            Section {
                ForEach(
                    Homepage.allCases,
                    id: \.self,
                    content: row
                )
            } footer: {
                Text(
                    "This is the default screen you’ll see each time you open the app."
                )
            }
        }
        .navigationTitle(Homepage.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - View Builders

    private func row(for homepage: Homepage)
        -> some View
    {
        HStack {
            Text(homepage.label)
                .frame(maxWidth: .infinity, alignment: .leading)

            if homepage == settings.homepage {
                Image(systemName: "checkmark")
                    .fontWeight(.semibold)
                    .foregroundStyle(accentColor.swiftUiColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            settings.homepage = homepage
        }
    }
}
