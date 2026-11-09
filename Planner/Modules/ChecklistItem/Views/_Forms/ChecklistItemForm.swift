//
//  ChecklistItemForm.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

struct ChecklistItemFormView: View {
    private let sourceItem: ChecklistItem?
    private let parentItem: ChecklistItem?
    private let sortedSiblingItems: [ChecklistItem]?
    private let onDelete: (() -> Void)?

    // MARK: Create Checklist Item
    init(
        parentItem: ChecklistItem,
        sortedSiblingItems: [ChecklistItem]
    ) {
        self.sourceItem = nil
        self.parentItem = parentItem
        self.sortedSiblingItems = sortedSiblingItems
        self.onDelete = nil

        _draftChecklistItem = State(
            initialValue: ChecklistItem()
        )
    }

    // MARK: Edit Checklist Item
    init(
        sourceItem: ChecklistItem,
        onDelete: (() -> Void)? = nil
    ) {
        self.sourceItem = sourceItem
        self.parentItem = sourceItem.parent
        self.sortedSiblingItems = nil
        self.onDelete = onDelete

        _draftChecklistItem = State(
            initialValue: ChecklistItem(
                draftOf: sourceItem
            )
        )
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draftChecklistItem: ChecklistItem

    @State private var hasTitleAutoFocused = false
    @State private var showDeleteConfirmation = false

    @FocusState private var isTitleFocused: Bool
    @FocusState private var isNotesFocused: Bool
    @FocusState private var isValueFocused: Bool

    private var canSave: Bool {
        !draftChecklistItem.title.trimmed.isEmpty
    }

    private var isCreateForm: Bool {
        sourceItem == nil
    }

    private var color: Color {
        switch draftChecklistItem.type {
        case .item:
            return parentItem?.color.swiftUIColor(accentColor: accentColor)
                ?? Color.red
        case .checklist, .folder:
            return draftChecklistItem.color.swiftUIColor(
                accentColor: accentColor
            )
        }
    }

    private var showColorSection: Bool {
        draftChecklistItem.type != .item
    }

    private var showDeleteButton: Bool {
        sourceItem != nil && sourceItem!.parent != nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                FormTitleFieldView(
                    text: $draftChecklistItem.title,
                    hasAutoFocused: $hasTitleAutoFocused,
                    isFocused: $isTitleFocused
                )
                .textInputAutocapitalization(.words)

                typeSection
                colorSection
                advancedSection
            }
            .scrollDisabled(true)
            .toolbar {
                cancelButton

                FormSaveButtonView(
                    canSave: canSave,
                    tint: draftChecklistItem.title.isEmpty
                        ? Color.label : color,
                    save: saveChecklistItem
                )

                deleteButton
            }
            .navigationTitle(
                isCreateForm
                    ? "Create Item"
                    : "Edit \(draftChecklistItem.type.rawValue.capitalized)"
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        .safeAreaBar(edge: .bottom) {
            keyboardAdornment
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            CancelButtonView {
                dismiss()
            }
        }
    }

    @ToolbarContentBuilder
    private var deleteButton: some ToolbarContent {
        if showDeleteButton, let sourceItem {
            ToolbarItem(placement: .bottomBar) {
                ActionButtonView(
                    label: "Delete \(sourceItem.type.rawValue.capitalized)",
                    systemImage: "trash",
                    color: Color.red,
                    onTap: {
                        showDeleteConfirmation = true
                    }
                )
                .withConfirmation(
                    deleteChecklistItemConfig(
                        item: sourceItem,
                        inForm: true,
                        delete: deleteChecklistItem
                    ),
                    isPresented: $showDeleteConfirmation
                )
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var typeSection: some View {
        if isCreateForm {
            Section {
                Picker("", selection: $draftChecklistItem.type) {
                    Text("Checklist").tag(ChecklistItemType.checklist)
                    Text("Folder").tag(ChecklistItemType.folder)
                }
                .pickerStyle(.segmented)
            }
            .listSectionMargins(.vertical, 0)
            .discreetListItem()
        }
    }

    @ViewBuilder
    private var colorSection: some View {
        if showColorSection {
            Section {
                HStack {
                    ZStack {
                        Image(
                            systemName: .accent
                                == draftChecklistItem.color
                                ? "square.fill" : "square"
                        )
                        .imageScale(.large)
                        .foregroundColor(accentColor.swiftUiColor)

                        VStack {
                            Spacer()

                            AdornedValue(
                                "Accent",
                                iconConfig: IconConfig(name: "gear"),
                                color: Color.secondary,
                                scale: 0.6
                            )
                            .offset(y: 16)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        draftChecklistItem.color = .accent
                    }

                    Divider()

                    ForEach(
                        ChecklistItemColor.allCases.enumerated(),
                        id: \.element
                    ) {
                        index,
                        itemColor in
                        if itemColor != .accent {
                            if index != 0 {
                                Spacer()
                            }

                            Image(
                                systemName: itemColor
                                    == draftChecklistItem.color
                                    ? "circle.fill" : "circle"
                            )
                            .imageScale(.large)
                            .foregroundColor(
                                itemColor.swiftUIColor(accentColor: accentColor)
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                draftChecklistItem.color = itemColor
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom)
            }
            .listSectionMargins(.vertical, 0)
            .discreetListItem()
        }
    }

    private var advancedSection: some View {
        Section("Advanced") {
            switch draftChecklistItem.type {
            case .item:
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $draftChecklistItem.notes)
                        .focused($isNotesFocused)
                        .scrollContentBackground(.hidden)

                    if draftChecklistItem.notes.trimmed.isEmpty {
                        Text("Notes")
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 5)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
                .frame(height: 200)

                whenSection

                HStack {
                    Text("Value")

                    CurrencyTextFieldView(
                        value: $draftChecklistItem.valueInt,
                        textColor: isValueFocused
                            || draftChecklistItem.draftValue.isZero
                            ? Color.label
                            : draftChecklistItem.draftValue < 0
                                ? Color.red : Color.green
                    )
                    .focused($isValueFocused)
                    .tint(color)
                }

            case .folder, .checklist:
                Picker(
                    ChecklistItemFinanceVariant.title,
                    selection: $draftChecklistItem.financeVariant
                ) {
                    ForEach(
                        ChecklistItemFinanceVariant.allCases,
                        id: \.self
                    ) { variant in
                        Text(variant.label)
                            .tag(variant)
                    }
                }
                .tint(color)

                if draftChecklistItem.type == .checklist {
                    Toggle(
                        "Hide Toggles",
                        isOn: $draftChecklistItem.hideToggles
                    )
                    .tint(color)
                }
            }
        }
    }

    @ViewBuilder
    private var whenSection: some View {
        HStack(spacing: 2) {
            Text("When")

            Menu {
                Button("--") {
                    draftChecklistItem.month = nil
                }

                ForEach(1...12, id: \.self) { month in
                    Button(DateFormatter().monthSymbols[month - 1]) {
                        draftChecklistItem.month = month
                    }
                }
            } label: {
                ZStack {
                    if let month = draftChecklistItem.month {
                        Text(DateFormatter().monthSymbols[month - 1])
                            .font(
                                .system(
                                    size: 16,
                                    weight: .heavy,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(Color.label)
                    } else {
                        Text("Month")
                            .foregroundStyle(Color.tertiary)
                    }
                }
                .glassChip(height: 30)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            Menu {
                Button("--") {
                    draftChecklistItem.day = nil
                }

                ForEach(1...31, id: \.self) { day in
                    Button("\(day)") {
                        draftChecklistItem.day = day
                    }
                }
            } label: {
                ZStack {
                    if let day = draftChecklistItem.day {
                        Text("\(day)")
                            .font(
                                .system(
                                    size: 16,
                                    weight: .heavy,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(Color.label)
                    } else {
                        Text("Day")
                            .foregroundStyle(Color.tertiary)
                    }
                }
                .glassChip(height: 30)
            }

            Menu {
                Button("--") {
                    draftChecklistItem.year = nil
                }

                ForEach(
                    (Calendar.current.component(.year, from: .now) - 10)...(Calendar
                        .current.component(.year, from: .now) + 10),
                    id: \.self
                ) { year in
                    Button(String(year)) {
                        draftChecklistItem.year = year
                    }
                }
            } label: {
                ZStack {
                    if let year = draftChecklistItem.year {
                        Text(String(year))
                            .font(
                                .system(
                                    size: 16,
                                    weight: .heavy,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(Color.label)
                    } else {
                        Text("Year")
                            .foregroundStyle(Color.tertiary)
                    }
                }
                .glassChip(height: 30)
            }
        }
    }

    @ViewBuilder
    private var keyboardAdornment: some View {
        if isValueFocused || isNotesFocused || isTitleFocused {
            HStack(alignment: .bottom) {

                if isValueFocused {
                    Picker(
                        "",
                        selection: $draftChecklistItem.valueSign
                    ) {
                        Text("−").tag(-1)
                        Text("+").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 100)
                }

                Spacer()

                GlassIconButtonView(
                    systemImageName: "checkmark",
                    onTap: {
                        isValueFocused = false
                        isNotesFocused = false
                        isTitleFocused = false
                    }
                )
            }
            .padding(8)
        }
    }

    // MARK: - Functions

    private func saveChecklistItem() {
        modelContext.saveChecklistItem(
            sourceItem: sourceItem,
            parentItem: parentItem,
            sortedSiblingItems: sortedSiblingItems,
            draftItem: draftChecklistItem
        )

        dismiss()
    }

    private func deleteChecklistItem() {
        guard let sourceItem else { return }

        dismiss()

        modelContext.safeDelete(sourceItem)
        onDelete?()
    }
}
