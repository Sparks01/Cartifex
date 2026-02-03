//
//  CatalogView.swift
//  ItemCardCreatorapp
//
//  Features:
//    - Unified import path via CardImporter
//    - Spells have Quick Save parity with other categories
//    - Multi-select with batch import to any collection
//    - Spell class filter
//    - Expandable description preview on each row
//    - Duplicate detection ("Saved" badge on items already in library)
//    - Result count in toolbar
//    - Safe spell.name unwrapping (no force unwrap)
//    - Save confirmation toast
//

import SwiftUI
import SwiftData

struct CatalogView: View {
    let onItemSelected: ((Open5eItem) -> Void)?

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var dataStore = CatalogDataStore.shared

    @Query(sort: \CardCollection.name) private var collections: [CardCollection]

    // Dupe detection: all card titles already in the user's library
    @Query private var existingCards: [Card]

    // View state
    @State private var mode: CatalogMode = .magicItems
    @State private var selectedSource: String? = nil
    @State private var availableSources: [V2Source] = []
    @State private var searchText = ""
    @State private var isLoadingSources = false

    // Magic Items filters
    @State private var selectedCategory: String? = nil
    @State private var selectedRarity: String? = nil

    // Spell filters
    @State private var selectedSpellClass: String? = nil

    // Multi-select state
    @State private var selectedCardIDs: Set<PersistentIdentifier> = []
    @State private var selectedSpellIDs: Set<String> = []

    // Preview state
    @State private var expandedCardID: PersistentIdentifier? = nil
    @State private var expandedSpellName: String? = nil

    // Save confirmation
    @State private var saveConfirmation: String? = nil

    enum CatalogMode: String, CaseIterable {
        case magicItems = "Magic Items"
        case spells = "Spells"
        case weapons = "Weapons"
        case armor = "Armor"
        
        var icon: String {
            switch self {
            case .magicItems: return "wand.and.stars"
            case .spells: return "sparkles"
            case .weapons: return "figure.fencing"
            case .armor: return "shield"
            }
        }
        
        var color: Color {
            switch self {
            case .magicItems: return .purple
            case .spells: return .purple
            case .weapons: return .red
            case .armor: return .blue
            }
        }
    }

    init(onItemSelected: ((Open5eItem) -> Void)? = nil) {
        self.onItemSelected = onItemSelected
    }

    // MARK: - Dupe Detection

    /// Set of titles already saved in the user's library for fast lookup.
    private var savedTitles: Set<String> {
        Set(existingCards.map { $0.title })
    }

    // MARK: - Filtered Results

    private var displayedCards: [Card] {
        switch mode {
        case .magicItems:
            return dataStore.filteredMagicItems(
                source: selectedSource,
                search: searchText,
                category: selectedCategory,
                rarity: selectedRarity
            )
        case .weapons:
            return dataStore.filteredWeapons(source: selectedSource, search: searchText)
        case .armor:
            return dataStore.filteredArmor(source: selectedSource, search: searchText)
        case .spells:
            return []
        }
    }

    private var displayedSpells: [Open5eItem] {
        guard mode == .spells else { return [] }
        return dataStore.filteredSpells(source: selectedSource, search: searchText, spellClass: selectedSpellClass)
    }

    /// Total count of currently visible results.
    private var resultCount: Int {
        mode == .spells ? displayedSpells.count : displayedCards.count
    }

    /// Total selected items in the current mode.
    private var selectionCount: Int {
        mode == .spells ? selectedSpellIDs.count : selectedCardIDs.count
    }

    /// Whether every visible item is selected.
    private var allVisibleSelected: Bool {
        if mode == .spells {
            let visible = displayedSpells.compactMap { $0.name }
            return !visible.isEmpty && visible.allSatisfy { selectedSpellIDs.contains($0) }
        } else {
            let visible = displayedCards.map { $0.persistentModelID }
            return !visible.isEmpty && visible.allSatisfy { selectedCardIDs.contains($0) }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                toolbarArea
                resultsList

                if selectionCount > 0 {
                    batchImportBar
                }
            }
            .overlay(alignment: .bottom) {
                saveToast
                    .padding(.bottom, selectionCount > 0 ? 60 : 0)
            }
            .navigationTitle("Open5e Catalog")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            await loadSources()
        }
    }

    // MARK: - Toolbar Area

    private var toolbarArea: some View {
        VStack(spacing: 12) {
            // Row 1: Source + mode + refresh
            HStack(spacing: 16) {
                if isLoadingSources {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Loading sources\u{2026}")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 6) {
                        Text("Source:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Source", selection: $selectedSource) {
                            Text("All Sources").tag(nil as String?)
                            ForEach(availableSources) { source in
                                Text(source.displayName).tag(source.key as String?)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    ForEach(CatalogMode.allCases, id: \.self) { m in
                        let isSelected = mode == m
                        Button {
                            mode = m
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: m.icon)
                                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                                Text(m.rawValue)
                                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? m.color.opacity(0.15) : Color.secondary.opacity(0.06))
                            .foregroundColor(isSelected ? m.color : .secondary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? m.color.opacity(0.4) : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onChange(of: mode) { _, _ in
                    selectedCategory = nil
                    selectedRarity = nil
                    selectedSpellClass = nil
                    expandedCardID = nil
                    expandedSpellName = nil
                    clearSelection()
                }

                Spacer()

                Button {
                    Task { await dataStore.loadAllDataFromAPI(forceRefresh: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(dataStore.isLoading)
                .help(refreshTooltip)
            }

            // Row 2: Search + filters + result count
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search\u{2026}", text: $searchText)

                    // Result count — inline at end of search bar
                    if dataStore.hasLoadedOnce {
                        Text("\(resultCount)")
                            .font(.caption.monospacedDigit().bold())
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)

                if mode == .magicItems {
                    Picker("Type", selection: $selectedCategory) {
                        Text("All Types").tag(nil as String?)
                        Text("Potion").tag("Potion" as String?)
                        Text("Ring").tag("Ring" as String?)
                        Text("Rod").tag("Rod" as String?)
                        Text("Scroll").tag("Scroll" as String?)
                        Text("Staff").tag("Staff" as String?)
                        Text("Wand").tag("Wand" as String?)
                        Text("Wondrous Item").tag("Wondrous Item" as String?)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .fixedSize()

                    Picker("Rarity", selection: $selectedRarity) {
                        Text("All Rarities").tag(nil as String?)
                        Text("Common").tag("Common" as String?)
                        Text("Uncommon").tag("Uncommon" as String?)
                        Text("Rare").tag("Rare" as String?)
                        Text("Very Rare").tag("Very Rare" as String?)
                        Text("Legendary").tag("Legendary" as String?)
                        Text("Artifact").tag("Artifact" as String?)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .fixedSize()

                    if selectedCategory != nil || selectedRarity != nil {
                        Button {
                            selectedCategory = nil
                            selectedRarity = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if mode == .spells {
                    Picker("Class", selection: $selectedSpellClass) {
                        Text("All Classes").tag(nil as String?)
                        Text("Barbarian").tag("Barbarian" as String?)
                        Text("Bard").tag("Bard" as String?)
                        Text("Cleric").tag("Cleric" as String?)
                        Text("Druid").tag("Druid" as String?)
                        Text("Fighter").tag("Fighter" as String?)
                        Text("Monk").tag("Monk" as String?)
                        Text("Paladin").tag("Paladin" as String?)
                        Text("Ranger").tag("Ranger" as String?)
                        Text("Rogue").tag("Rogue" as String?)
                        Text("Sorcerer").tag("Sorcerer" as String?)
                        Text("Warlock").tag("Warlock" as String?)
                        Text("Wizard").tag("Wizard" as String?)
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .fixedSize()

                    if selectedSpellClass != nil {
                        Button {
                            selectedSpellClass = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if dataStore.isLoading {
                HStack {
                    ProgressView().controlSize(.small)
                    Text(dataStore.loadProgress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Results List

    private var resultsList: some View {
        List {
            if resultCount > 0 {
                selectAllRow
            }

            if mode == .spells {
                if displayedSpells.isEmpty {
                    emptyState
                } else {
                    ForEach(displayedSpells.filter { $0.name != nil }) { spell in
                        spellRow(for: spell)
                    }
                }
            } else {
                if displayedCards.isEmpty {
                    emptyState
                } else {
                    ForEach(displayedCards) { card in
                        cardRow(for: card)
                    }
                }
            }
        }
    }

    // MARK: - Select All Row

    private var selectAllRow: some View {
        HStack {
            Button {
                toggleSelectAll()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: allVisibleSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(allVisibleSelected ? .accentColor : .secondary)
                        .font(.title3)

                    Text(allVisibleSelected ? "Deselect All" : "Select All")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)

                    Text("(\(resultCount) items)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            if selectionCount > 0 {
                Text("\(selectionCount) selected")
                    .font(.caption.bold())
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }

    // MARK: - Batch Import Bar

    private var batchImportBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("\(selectionCount) selected")
                        .font(.callout.bold())
                }

                Spacer()

                Button("Clear") {
                    withAnimation { clearSelection() }
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)

                Button {
                    batchImport(to: nil)
                } label: {
                    Label("Add to Workspace", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.bordered)

                if !collections.isEmpty {
                    Menu {
                        ForEach(collections) { collection in
                            Button {
                                batchImport(to: collection)
                            } label: {
                                Label(collection.name, systemImage: collection.icon)
                            }
                        }
                    } label: {
                        Label("Add to Collection", systemImage: "folder.badge.plus")
                    }
                    .menuStyle(.borderedButton)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(NSColor.windowBackgroundColor))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Save Toast

    private var saveToast: some View {
        Group {
            if let message = saveConfirmation {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(message)
                        .font(.callout.bold())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: saveConfirmation)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            if !dataStore.hasLoadedOnce {
                ProgressView().controlSize(.large)
                Text("Loading catalog\u{2026}")
                    .font(.headline)
                Text("This may take a moment on first launch")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("No results found")
                    .font(.headline)
                Text("Try different filters or search terms")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    // MARK: - Saved Badge

    /// Small "Saved" badge shown on items that already exist in the user's library.
    private var savedBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "checkmark")
                .font(.system(size: 8, weight: .bold))
            Text("Saved")
        }
        .font(.system(size: 9, weight: .semibold))
        .foregroundColor(.green)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.green.opacity(0.12))
        .cornerRadius(4)
    }

    // MARK: - Card Row

    private func cardRow(for card: Card) -> some View {
        let isSelected = selectedCardIDs.contains(card.persistentModelID)
        let isExpanded = expandedCardID == card.persistentModelID
        let isSaved = savedTitles.contains(card.title)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title3)

                // Content
                VStack(alignment: .leading) {
                    HStack(spacing: 6) {
                        Text(card.title)
                            .font(.headline)

                        if isSaved {
                            savedBadge
                        }
                    }

                    HStack {
                        let fragments = cardDetailFragments(for: card)
                        ForEach(Array(fragments.enumerated()), id: \.offset) { index, fragment in
                            if index > 0 {
                                Text("\u{2022}").foregroundColor(.secondary)
                            }
                            Text(fragment)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Preview toggle
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandedCardID = isExpanded ? nil : card.persistentModelID
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Preview description")

                // Save menu
                saveMenu(title: card.title) { collection in
                    let newCard = CardImporter.importCard(card, collection: collection)
                    modelContext.insert(newCard)
                } onEditInForm: {
                    let newCard = CardImporter.importCard(card)
                    modelContext.insert(newCard)
                    dismiss()
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                toggleCardSelection(card)
            }

            // Expandable preview
            if isExpanded {
                cardPreview(description: card.itemDescription)
            }
        }
    }

    private func cardDetailFragments(for card: Card) -> [String] {
        var fragments: [String] = []
        if let magic = card.magicItemDetails {
            fragments.append(magic.type)
            fragments.append(magic.rarity)
        }
        if let weapon = card.weaponDetails {
            fragments.append(weapon.isSimple ? "Simple" : "Martial")
            fragments.append("\(weapon.damageDice) \(weapon.damageType)")
        }
        if let armor = card.armorDetails {
            fragments.append(armor.category)
            fragments.append("AC \(armor.ac)")
        }
        fragments.append(card.source)
        return fragments
    }

    // MARK: - Spell Row

    private func spellRow(for spell: Open5eItem) -> some View {
        // Safe unwrap — no more force unwrap
        guard let spellName = spell.name else {
            return AnyView(EmptyView())
        }

        let isSelected = selectedSpellIDs.contains(spellName)
        let isExpanded = expandedSpellName == spellName
        let isSaved = savedTitles.contains(spellName)

        return AnyView(
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    // Checkbox
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .font(.title3)

                    // Content
                    VStack(alignment: .leading) {
                        HStack(spacing: 6) {
                            Text(spellName)
                                .font(.headline)

                            if isSaved {
                                savedBadge
                            }
                        }

                        HStack {
                            Text(spell.level ?? "Cantrip")
                            Text("\u{2022}")
                            Text(spell.school ?? "Magic")

                            if spell.concentration == true {
                                Text("\u{2022}")
                                HStack(spacing: 2) {
                                    Text("\u{23F1}").font(.system(size: 8))
                                    Text("CONC")
                                }
                                .font(.system(size: 7, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(3)
                            }

                            if let classes = spell.classes, !classes.isEmpty {
                                Text("\u{2022}")
                                Text(classes)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            if let source = spell.document_title, !source.isEmpty {
                                Text("\u{2022}")
                                Text(source)
                                    .font(.system(size: 10))
                                    .foregroundColor(.blue)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Preview toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedSpellName = isExpanded ? nil : spellName
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Preview description")

                    // Save menu
                    saveMenu(title: spellName) { collection in
                        if let newCard = CardImporter.importSpell(spell, collection: collection) {
                            modelContext.insert(newCard)
                        }
                    } onEditInForm: {
                        if let onItemSelected = onItemSelected {
                            onItemSelected(spell)
                            dismiss()
                        } else {
                            if let newCard = CardImporter.importSpell(spell) {
                                modelContext.insert(newCard)
                            }
                            dismiss()
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleSpellSelection(spell)
                }

                // Expandable preview
                if isExpanded {
                    cardPreview(description: spell.desc ?? "No description available.")
                }
            }
        )
    }

    // MARK: - Expandable Preview

    /// Shared preview panel shown below a row when expanded.
    private func cardPreview(description: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
            Text(description)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(8)
                .fixedSize(horizontal: false, vertical: true)

            if description.count > 400 {
                Text("Showing preview \u{2014} use Edit in Form for full text")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.leading, 44)  // Align with content (past checkbox)
        .padding(.top, 6)
        .padding(.bottom, 4)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Reusable Save Menu

    private func saveMenu(
        title: String,
        onQuickSave: @escaping (CardCollection?) -> Void,
        onEditInForm: @escaping () -> Void
    ) -> some View {
        Menu {
            Button {
                onEditInForm()
            } label: {
                Label("Edit in Form", systemImage: "pencil")
            }

            Divider()

            Section("Quick Save To:") {
                Button("Library (No Collection)") {
                    onQuickSave(nil)
                    showSaveConfirmation("Saved \"\(title)\"")
                }

                ForEach(collections) { collection in
                    Button {
                        onQuickSave(collection)
                        showSaveConfirmation("Saved \"\(title)\"")
                    } label: {
                        Label(collection.name, systemImage: collection.icon)
                    }
                }
            }
        } label: {
            Image(systemName: "square.and.arrow.down")
                .foregroundColor(.blue)
        }
        .menuStyle(.borderlessButton)
        .frame(width: 30)
    }

    // MARK: - Selection Logic

    private func toggleCardSelection(_ card: Card) {
        let id = card.persistentModelID
        if selectedCardIDs.contains(id) {
            selectedCardIDs.remove(id)
        } else {
            selectedCardIDs.insert(id)
        }
    }

    private func toggleSpellSelection(_ spell: Open5eItem) {
        guard let name = spell.name else { return }
        if selectedSpellIDs.contains(name) {
            selectedSpellIDs.remove(name)
        } else {
            selectedSpellIDs.insert(name)
        }
    }

    private func toggleSelectAll() {
        if allVisibleSelected {
            clearSelection()
        } else {
            if mode == .spells {
                selectedSpellIDs.formUnion(displayedSpells.compactMap { $0.name })
            } else {
                selectedCardIDs.formUnion(displayedCards.map { $0.persistentModelID })
            }
        }
    }

    private func clearSelection() {
        selectedCardIDs.removeAll()
        selectedSpellIDs.removeAll()
    }

    // MARK: - Batch Import

    private func batchImport(to collection: CardCollection?) {
        var importedCount = 0

        if mode == .spells {
            let spellsToImport = displayedSpells.filter { spell in
                guard let name = spell.name else { return false }
                return selectedSpellIDs.contains(name)
            }
            for spell in spellsToImport {
                if let newCard = CardImporter.importSpell(spell, collection: collection) {
                    modelContext.insert(newCard)
                    importedCount += 1
                }
            }
        } else {
            let cardsToImport = displayedCards.filter { card in
                selectedCardIDs.contains(card.persistentModelID)
            }
            for card in cardsToImport {
                let newCard = CardImporter.importCard(card, collection: collection)
                modelContext.insert(newCard)
                importedCount += 1
            }
        }

        let destination = collection?.name ?? "Library"
        showSaveConfirmation("Imported \(importedCount) items to \(destination)")

        withAnimation {
            clearSelection()
        }
    }

    // MARK: - Helpers

    private var refreshTooltip: String {
        if let lastLoad = dataStore.lastLoadDate {
            return "Last updated \(lastLoad.formatted(.relative(presentation: .named))) \u{2014} click to refresh"
        }
        return "Refresh catalog from Open5e"
    }

    private func showSaveConfirmation(_ message: String) {
        withAnimation {
            saveConfirmation = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                if saveConfirmation == message {
                    saveConfirmation = nil
                }
            }
        }
    }

    private func loadSources() async {
        isLoadingSources = true
        do {
            availableSources = try await Open5eService.shared.fetchAvailableSources()

            availableSources.sort { a, b in
                if a.key == "srd-2024" { return true }
                if b.key == "srd-2024" { return false }
                if a.key == "srd-2014" { return true }
                if b.key == "srd-2014" { return false }
                return a.displayName < b.displayName
            }

           
        } catch {
            print("\u{274C} Failed to load sources: \(error)")
        }
        isLoadingSources = false
    }
}

