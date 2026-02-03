//
//  SidebarView.swift
//  ItemCardCreatorapp
//
//  Created by Jose Munoz on 12/9/25.
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Card.title) private var cards: [Card]
    
    @Bindable var viewModel: CardCreationViewModel
    @State private var errorAlert: ErrorAlert?
    @State private var showingDeleteConfirmation = false
    
    // Toast
    @State private var showSaveToast = false
    @State private var saveToastMessage = ""
    
    // Dirty form protection
    @State private var showDirtyFormAlert = false
    @State private var pendingAction: (() -> Void)? = nil
    
    @Query(sort: \CardCollection.name) private var collections: [CardCollection]
    @State private var showAddCollectionAlert = false
    @State private var newCollectionName = ""
    
    // Arrays for pickers
    let damageTypes = ["Bludgeoning", "Piercing", "Slashing", "Fire", "Cold", "Lightning", "Thunder", "Poison", "Acid", "Psychic", "Necrotic", "Radiant", "Force"]
    let armorTypes = ["Light", "Medium", "Heavy", "Shield"]
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Fixed Header
            headerSection
            
            // MARK: - Scrollable Form
            ScrollView {
                LazyVStack(spacing: 20) {
                    categoryPickerCard
                    basicInfoCard
                    
                    // Description — hidden for NPCs & Locations (integrated into their detail sections)
                    if viewModel.category != .npc && viewModel.category != .location {
                        descriptionCard
                    }
                    
                    dynamicDetailsCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            
            // MARK: - Pinned Bottom Bar
            bottomActionBar
        }
        .background(Color(NSColor.controlBackgroundColor))
        .sheet(isPresented: $viewModel.showCatalog) {
            CatalogView(onItemSelected: { apiItem in
                viewModel.loadFromOpen5eItem(apiItem)
            })
            .frame(minWidth: 700, minHeight: 600)
        }
        .alert(item: $errorAlert) { (alert: ErrorAlert) in
            Alert(
                title: Text("Error"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .confirmationDialog(
            "Delete All Cards",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) { deleteAllCards() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete all \(cards.count) cards. This action cannot be undone.")
        }
        // Dirty form warning
        .alert("Unsaved Changes", isPresented: $showDirtyFormAlert) {
            Button("Discard", role: .destructive) {
                pendingAction?()
                pendingAction = nil
            }
            Button("Cancel", role: .cancel) {
                pendingAction = nil
            }
        } message: {
            Text("You have unsaved changes in the form. Discard them?")
        }
        // Save toast overlay
        .overlay(alignment: .bottom) {
            if showSaveToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(saveToastMessage)
                        .font(.subheadline.bold())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 60)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSaveToast)
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: viewModel.isEditing ? "pencil.circle.fill" : categoryIcon)
                    .font(.title2)
                    .foregroundStyle(viewModel.isEditing ? .orange : categoryColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    if viewModel.isEditing {
                        Text("Editing")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(viewModel.title.isEmpty ? "Card" : viewModel.title)
                            .font(.caption)
                            .foregroundColor(.orange)
                            .lineLimit(1)
                    } else {
                        Text("Create Card")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Build your RPG collection")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if viewModel.isEditing {
                    Button {
                        viewModel.cancelEditing()
                    } label: {
                        Label("Cancel Edit", systemImage: "xmark.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.orange)
                } else {
                    // Quick category stats (inline pills)
                    Menu {
                        if !cards.isEmpty {
                            Button(role: .destructive) {
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete All Cards…", systemImage: "trash.slash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            Divider()
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Quick Stats (header)
    
    private var quickStatsView: some View {
        HStack(spacing: 3) {
            ForEach(CardCategory.allCases, id: \.self) { category in
                let count = cards.filter { $0.category == category }.count
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2.bold())
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(colorForCategory(category).opacity(0.15))
                        .foregroundColor(colorForCategory(category))
                        .cornerRadius(4)
                        .help("\(count) \(category.rawValue) card\(count == 1 ? "" : "s")")
                }
            }
            
            Text("\(cards.count)")
                .font(.title2.bold())
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Category Picker Card
    
    private var categoryPickerCard: some View {
        ModernCard {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "square.grid.2x2")
                        .foregroundColor(.secondary)
                    Text("Card Type")
                        .font(.headline)
                    
                    Spacer()
                    
                    if viewModel.isEditing {
                        Text("Locked")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                // One-tap icon grid
                let categories: [CardCategory] = [.item, .spell, .weapon, .armor, .npc, .location]
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                    ForEach(categories, id: \.self) { category in
                        let isSelected = viewModel.category == category
                        let color = colorForCategory(category)
                        
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewModel.category = category
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: iconForCategory(category))
                                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                                Text(category.rawValue)
                                    .font(.caption2.weight(isSelected ? .bold : .medium))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                isSelected
                                    ? color.opacity(0.15)
                                    : Color.secondary.opacity(0.05)
                            )
                            .foregroundColor(isSelected ? color : .secondary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isEditing)
                    }
                }

                // Catalog banner
                Button {
                    viewModel.showCatalog = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "books.vertical.fill")
                            .font(.body)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Browse Open5e Catalog")
                                .font(.subheadline.bold())
                            Text("Import spells, items, weapons & armor")
                                .font(.caption2)
                                .opacity(0.8)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                            .opacity(0.6)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .foregroundColor(.white)
                    .background(
                        LinearGradient(
                            colors: [Color.indigo, Color.indigo.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Basic Info Card
    
    private var basicInfoCard: some View {
        ModernCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("Basic Information")
                        .font(.headline)
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    ModernTextField(
                        title: "Name",
                        text: $viewModel.title,
                        placeholder: "Enter card name",
                        systemImage: "textformat"
                    )
                    
                    ModernTextField(
                        title: "Source",
                        text: $viewModel.source,
                        placeholder: "Source book/page",
                        systemImage: "book"
                    )
                }
                
                Divider()
                
                // Collection picker
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Save to")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Picker("", selection: $viewModel.selectedCollection) {
                            Text("No Collection").tag(nil as CardCollection?)
                            
                            if !collections.isEmpty {
                                Divider()
                                ForEach(collections) { collection in
                                    HStack {
                                        Image(systemName: collection.icon)
                                        Text(collection.name)
                                    }
                                    .tag(collection as CardCollection?)
                                }
                            }
                        }
                        .labelsHidden()
                        .fixedSize()
                        
                        Button {
                            showAddCollectionAlert = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.borderless)
                        .help("Create New Collection")
                    }
                }
            }
        }
        .alert("New Collection", isPresented: $showAddCollectionAlert) {
            TextField("Collection Name", text: $newCollectionName)
            Button("Cancel", role: .cancel) { }
            Button("Create") {
                let newCol = CardCollection(name: newCollectionName)
                modelContext.insert(newCol)
                viewModel.selectedCollection = newCol
                newCollectionName = ""
            }
        }
    }
    
    // MARK: - Dynamic Details Card
    
    private var dynamicDetailsCard: some View {
        ModernCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: categoryIcon)
                        .foregroundStyle(categoryColor)
                    Text("\(viewModel.category.rawValue) Details")
                        .font(.headline)
                    Spacer()
                }
                
                Group {
                    switch viewModel.category {
                    case .item, .magicItem:
                        itemDetailsView
                    case .spell:
                        spellDetailsView
                    case .weapon:
                        weaponDetailsView
                    case .armor:
                        armorDetailsView
                    case .npc:
                        npcDetailsView
                    case .location:
                        locationDetailsView
                    }
                }
            }
        }
    }
    
    // MARK: - Description Card (items, spells, weapons, armor only)
    
    private var descriptionCard: some View {
        ModernCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.secondary)
                    Text("Description")
                        .font(.headline)
                    Spacer()
                    
                    Text("\(viewModel.description.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
                
                TextEditor(text: $viewModel.description)
                    .frame(minHeight: 50)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Pinned Bottom Action Bar
    
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                if viewModel.isEditing {
                    // Cancel editing
                    Button {
                        guardDirtyForm {
                            viewModel.cancelEditing()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Cancel")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut(.escape, modifiers: [])
                } else {
                    // Magic wand — sample data loader
                    Menu {
                        Text("NPCs").font(.caption).foregroundColor(.secondary)
                        Button("Sample: Quest Giver") { viewModel.populateSampleNPC(variant: 1) }
                        Button("Sample: The Muscle") { viewModel.populateSampleNPC(variant: 2) }
                        Button("Sample: The Schemer") { viewModel.populateSampleNPC(variant: 3) }
                        
                        Divider()
                        
                        Text("Locations").font(.caption).foregroundColor(.secondary)
                        Button("Sample: Dungeon") { viewModel.populateSampleLocation(variant: 1) }
                        Button("Sample: Tavern") { viewModel.populateSampleLocation(variant: 2) }
                        Button("Sample: Wilderness") { viewModel.populateSampleLocation(variant: 3) }
                    } label: {
                        Image(systemName: "wand.and.rays")
                            .font(.system(size: 14))
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 30)
                    .help("Load Sample Data")
                }
                
                // Primary action — ⌘S
                Button(action: saveCard) {
                    HStack {
                        Image(systemName: viewModel.canAddCard
                              ? (viewModel.isEditing ? "checkmark.circle.fill" : "plus.circle.fill")
                              : "exclamationmark.triangle")
                        Text(viewModel.canAddCard
                             ? (viewModel.isEditing ? "Save Changes" : "Add Card")
                             : (viewModel.validationMessage ?? "Invalid"))
                    }
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.isEditing ? .orange : nil)
                .controlSize(.large)
                .disabled(!viewModel.canAddCard)
                .keyboardShortcut("s", modifiers: .command)
                
                if !viewModel.isEditing {
                    // Clear form — ⌘⌫
                    Button {
                        guardDirtyForm {
                            viewModel.clearAllFields()
                        }
                    } label: {
                        Image(systemName: "eraser")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.secondary)
                    .help("Clear all form fields (⌘⌫)")
                    .keyboardShortcut(.delete, modifiers: .command)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    
    
}


// MARK: - Detail Views Extension

extension SidebarView {

    // MARK: Helper Properties

    private var categoryColor: Color {
        colorForCategory(viewModel.category)
    }

    private func colorForCategory(_ category: CardCategory) -> Color {
        switch category {
        case .spell: return .purple
        case .npc: return .orange
        case .location: return .green
        case .item: return .blue
        case .weapon: return .red
        case .armor: return .blue
        case .magicItem: return .purple
        }
    }

    private var categoryIcon: String {
        iconForCategory(viewModel.category)
    }

    private func iconForCategory(_ category: CardCategory) -> String {
        switch category {
        case .spell: return "sparkles"
        case .npc: return "person.crop.circle"
        case .location: return "map"
        case .item: return "cube"
        case .weapon: return "figure.fencing"
        case .armor: return "shield"
        case .magicItem: return "wand.and.stars"
        }
    }

    // MARK: - Item Details

    private var itemDetailsView: some View {
        VStack(spacing: 12) {
            ModernTextField(
                title: "Type",
                text: $viewModel.itemType,
                placeholder: "e.g. Ring, Weapon, Armor",
                systemImage: "tag"
            )

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rarity").font(.caption).foregroundColor(.secondary)
                    Picker("Rarity", selection: $viewModel.itemRarity) {
                        ForEach(viewModel.rarities, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Attunement").font(.caption).foregroundColor(.secondary)
                    Toggle("Required", isOn: $viewModel.requiresAttunement)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }
            }

            if viewModel.requiresAttunement {
                ModernTextField(
                    title: "Attunement Details",
                    text: $viewModel.attunementDetail,
                    placeholder: "by a Wizard",
                    systemImage: "person.crop.circle.badge.exclamationmark"
                )
            }

            ModernTextField(
                title: "Magic Bonus",
                text: $viewModel.magicBonus,
                placeholder: "+1, +2",
                systemImage: "wand.and.stars"
            )
        }
    }

    // MARK: - Weapon Details

    private var weaponDetailsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ModernTextField(title: "Damage", text: $viewModel.damageDice, placeholder: "1d8", systemImage: "die.face.5")

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame").font(.caption).foregroundColor(.secondary)
                        Text("Type").font(.caption).foregroundColor(.secondary)
                    }
                    Picker("", selection: $viewModel.damageType) {
                        Text("-").tag("")
                        ForEach(damageTypes, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }

            HStack(spacing: 12) {
                ModernTextField(title: "Range", text: $viewModel.weaponRange, placeholder: "20/60", systemImage: "arrow.up.right")
                ModernTextField(title: "Mastery", text: $viewModel.mastery, placeholder: "Topple", systemImage: "star.circle")
            }

            HStack {
                ModernTextField(title: "Properties", text: $viewModel.weaponProperties, placeholder: "Light, Finesse", systemImage: "list.bullet")
                Toggle("Simple", isOn: $viewModel.isSimple)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            Divider().padding(.vertical, 4)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rarity").font(.caption).foregroundStyle(.secondary)
                    Picker("Rarity", selection: $viewModel.itemRarity) {
                        ForEach(viewModel.rarities, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                ModernTextField(title: "Bonus", text: $viewModel.magicBonus, placeholder: "+1", systemImage: "wand.and.stars")
            }

            VStack(spacing: 8) {
                Toggle("Requires Attunement", isOn: $viewModel.requiresAttunement)
                    .toggleStyle(.switch)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if viewModel.requiresAttunement {
                    ModernTextField(title: "Details", text: $viewModel.attunementDetail, placeholder: "by a Fighter", systemImage: "person.crop.circle.badge.exclamationmark")
                }
            }
        }
    }

    // MARK: - Armor Details

    private var armorDetailsView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ModernTextField(title: "AC Value", text: $viewModel.armorACValue, placeholder: "14", systemImage: "shield")

                VStack(alignment: .leading, spacing: 6) {
                    Text("Category").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: $viewModel.armorCategoryType) {
                        Text("-").tag("")
                        ForEach(armorTypes, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Str Req").font(.caption).foregroundStyle(.secondary)
                    TextField("None", value: $viewModel.strengthReq, format: .number)
                        .textFieldStyle(.roundedBorder)
                }
                Spacer()
                Toggle("Stealth Disadv.", isOn: $viewModel.stealthDisadvantage)
                    .toggleStyle(.switch)
            }

            Divider().padding(.vertical, 4)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rarity").font(.caption).foregroundStyle(.secondary)
                    Picker("Rarity", selection: $viewModel.itemRarity) {
                        ForEach(viewModel.rarities, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                ModernTextField(title: "Bonus", text: $viewModel.magicBonus, placeholder: "+1", systemImage: "wand.and.stars")
            }

            VStack(spacing: 8) {
                Toggle("Requires Attunement", isOn: $viewModel.requiresAttunement)
                    .toggleStyle(.switch)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if viewModel.requiresAttunement {
                    ModernTextField(title: "Details", text: $viewModel.attunementDetail, placeholder: "by a Paladin", systemImage: "person.crop.circle.badge.exclamationmark")
                }
            }
        }
    }

    // MARK: - Spell Details

    private var spellDetailsView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Level").font(.caption).foregroundColor(.secondary)
                    Picker("Level", selection: $viewModel.spellLevel) {
                        ForEach(viewModel.spellLevels, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Text("School").font(.caption).foregroundColor(.secondary)
                    Picker("School", selection: $viewModel.spellSchool) {
                        ForEach(viewModel.schools, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ModernTextField(title: "Casting Time", text: $viewModel.castingTime, placeholder: "1 Action", systemImage: "clock")
                ModernTextField(title: "Range", text: $viewModel.range, placeholder: "60 feet", systemImage: "location")
                ModernTextField(title: "Components", text: $viewModel.components, placeholder: "V, S, M", systemImage: "hand.raised")
                ModernTextField(title: "Duration", text: $viewModel.duration, placeholder: "Instantaneous", systemImage: "timer")
            }

            HStack(spacing: 16) {
                Toggle("Concentration", isOn: $viewModel.concentration)
                    .toggleStyle(.switch).controlSize(.small)
                Toggle("Ritual", isOn: $viewModel.ritual)
                    .toggleStyle(.switch).controlSize(.small)
            }

            ModernTextField(title: "Classes", text: $viewModel.classes, placeholder: "Wizard, Sorcerer", systemImage: "person.3")
        }
    }

    // MARK: - NPC Details (collapsible freeform fields)

    private var npcDetailsView: some View {
        VStack(spacing: 16) {

            // ── Identity Section (always visible) ──────────────────────
            VStack(alignment: .leading, spacing: 8) {
                Label("Identity", systemImage: "person.text.rectangle")
                    .font(.headline)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ancestry").font(.caption).foregroundColor(.secondary)
                        Picker("Ancestry", selection: $viewModel.npcAncestry) {
                            ForEach(NPCAncestry.allCases, id: \.self) { ancestry in
                                Text(ancestry.displayName).tag(ancestry.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Role").font(.caption).foregroundColor(.secondary)
                        Picker("Role", selection: $viewModel.npcRole) {
                            ForEach(NPCRole.allCases, id: \.self) { role in
                                Text(role.rawValue).tag(role.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                ModernTextField(title: "Creature Type", text: $viewModel.npcSub, placeholder: "Medium Humanoid", systemImage: "person.2")
                ModernTextField(title: "Faction / Organization", text: $viewModel.npcFaction, placeholder: "The Church, Thieves Guild, etc.", systemImage: "flag")
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            // ── Statblock Section (always visible) ─────────────────────
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Statblock", systemImage: "doc.text")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Toggle("Custom Stats", isOn: $viewModel.npcUseCustomStats)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                if !viewModel.npcUseCustomStats {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Archetype").font(.caption).foregroundColor(.secondary)
                        Picker("Archetype", selection: $viewModel.npcArchetype) {
                            Text("Select...").tag(nil as NPCArchetype?)
                            ForEach(NPCArchetype.allCases, id: \.self) { archetype in
                                HStack {
                                    Image(systemName: archetype.icon)
                                    Text(archetype.rawValue)
                                }
                                .tag(archetype as NPCArchetype?)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: viewModel.npcArchetype) { _, _ in
                            viewModel.npcStatblockName = nil
                        }
                    }

                    if let archetype = viewModel.npcArchetype {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Statblock").font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Picker("Tier", selection: $viewModel.npcTier) {
                                    Text("T1").tag(1)
                                    Text("T2").tag(2)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 100)
                            }

                            let statblocks = NPCStatblockDatabase.shared.statblocks(for: archetype)
                            let tierStatblocks = statblocks.filter { $0.tier == viewModel.npcTier }

                            Picker("Statblock", selection: $viewModel.npcStatblockName) {
                                Text("Select...").tag(nil as String?)
                                ForEach(tierStatblocks) { statblock in
                                    Text(statblock.name).tag(statblock.name as String?)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: viewModel.npcStatblockName) { _, newValue in
                                if let name = newValue,
                                   let statblock = NPCStatblockDatabase.shared.statblock(name: name, archetype: archetype) {
                                    viewModel.loadNPCFromStatblock(statblock)
                                }
                            }
                        }

                        Text(archetype.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }

                HStack(spacing: 12) {
                    ModernTextField(title: "AC", text: $viewModel.npcAc, placeholder: "10", systemImage: "shield")
                        .disabled(!viewModel.npcUseCustomStats)
                    ModernTextField(title: "HP", text: $viewModel.npcHp, placeholder: "10", systemImage: "heart")
                        .disabled(!viewModel.npcUseCustomStats)
                    ModernTextField(title: "CR", text: $viewModel.npcCr, placeholder: "1/4", systemImage: "star")
                        .disabled(!viewModel.npcUseCustomStats)
                }

                if !viewModel.npcUseCustomStats && !viewModel.npcSignatureAction.isEmpty {
                    HStack {
                        Image(systemName: "bolt.fill").foregroundColor(.orange).font(.caption)
                        Text("Signature: \(viewModel.npcSignatureAction)")
                            .font(.caption).foregroundColor(.secondary)
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            // ── Freeform Fields (collapsible) ──────────────────────────

            FreeformFieldEditor(
                icon: "person.text.rectangle", iconColor: .teal,
                title: "CONCEPT", subtitle: "Visuals & Role",
                charLimit: 240, text: $viewModel.description
            )

            FreeformFieldEditor(
                icon: "theatermasks", iconColor: .blue,
                title: "PERSONA", subtitle: "Voice & Vibe",
                charLimit: 240, text: $viewModel.npcPersona
            )

            FreeformFieldEditor(
                icon: "target", iconColor: .orange,
                title: "DRIVE", subtitle: "Goals & Motivation",
                charLimit: 240, text: $viewModel.npcDrive,
                isRequired: true
            )

            FreeformFieldEditor(
                icon: "briefcase", iconColor: .green,
                title: "UTILITY", subtitle: "Info & Assets",
                charLimit: 240, text: $viewModel.npcUtility
            )

            FreeformFieldEditor(
                icon: "exclamationmark.triangle", iconColor: .red,
                title: "STAKES", subtitle: "Leverage & Limits",
                charLimit: 240, text: $viewModel.npcStakes
            )

            FreeformFieldEditor(
                icon: "note.text", iconColor: .purple,
                title: "NOTES", subtitle: "Session Tracking",
                charLimit: 240, text: $viewModel.npcPartyNotes
            )
        }
    }

    // MARK: - Location Details (collapsible freeform fields)

    private var locationDetailsView: some View {
        VStack(spacing: 12) {

            // ── Structural fields (always visible) ─────────────────────
            HStack(spacing: 12) {
                ModernTextField(title: "Type", text: $viewModel.locType, placeholder: "Landmark", systemImage: "building")
                ModernTextField(title: "Size", text: $viewModel.locSize, placeholder: "Small", systemImage: "ruler")
            }

            // DC Stepper
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "target").foregroundColor(.secondary)
                    Text("Difficulty Check (DC)").font(.caption).foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    Stepper(value: $viewModel.locDifficulty, in: 5...20) {
                        HStack {
                            Text("DC").font(.headline)
                            Text("\(viewModel.locDifficulty)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(getDCColor(difficulty: viewModel.locDifficulty))

                            Spacer()

                            Text(getDCLabel(difficulty: viewModel.locDifficulty))
                                .font(.caption)
                                .foregroundColor(getDCColor(difficulty: viewModel.locDifficulty))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(getDCColor(difficulty: viewModel.locDifficulty).opacity(0.15))
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }

            // ── Freeform Fields (collapsible) ──────────────────────────

            FreeformFieldEditor(
                icon: "cloud.sun", iconColor: .cyan,
                title: "ATMOSPHERE", subtitle: "Senses & Mood",
                charLimit: 240, text: $viewModel.description,
                startExpanded: true
            )

            FreeformFieldEditor(
                icon: "mappin.circle", iconColor: .blue,
                title: "POINTS OF INTEREST", subtitle: "Key Locations",
                charLimit: 240, text: $viewModel.locPointsOfInterest
            )

            FreeformFieldEditor(
                icon: "link", iconColor: .green,
                title: "HOOKS", subtitle: "Why Players Care",
                charLimit: 240, text: $viewModel.locHooks
            )

            FreeformFieldEditor(
                icon: "exclamationmark.octagon", iconColor: .orange,
                title: "HAZARDS", subtitle: "Dangers & Challenges",
                charLimit: 240, text: $viewModel.locHazards
            )

            FreeformFieldEditor(
                icon: "lock.circle", iconColor: .purple,
                title: "SECRETS", subtitle: "Hidden Elements",
                charLimit: 240, text: $viewModel.locSecrets
            )

            FreeformFieldEditor(
                icon: "note.text", iconColor: .red,
                title: "NOTES", subtitle: "Session Tracking",
                charLimit: 240, text: $viewModel.locNotes
            )
        }
    }

    // MARK: - DC Helpers

    private func getDCColor(difficulty: Int) -> Color {
        switch difficulty {
        case 5...10: return .green
        case 11...14: return .yellow
        case 15...18: return .orange
        default: return .red
        }
    }

    private func getDCLabel(difficulty: Int) -> String {
        switch difficulty {
        case 5...10: return "Low"
        case 11...14: return "Moderate"
        case 15...18: return "High"
        default: return "Deadly"
        }
    }

    // MARK: - Actions

        private func saveCard() {
            let cardName = viewModel.title
            let wasEditing = viewModel.isEditing
            do {
                try viewModel.saveCard(to: modelContext)
                // Show toast
                saveToastMessage = wasEditing
                    ? "\(cardName) updated ✓"
                    : "\(cardName) added to Library ✓"
                showSaveToast = true
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run { showSaveToast = false }
                }
            } catch {
                errorAlert = ErrorAlert(message: error.localizedDescription)
            }
        }
        
        /// Returns true if the form has meaningful content that would be lost.
        private var hasUnsavedWork: Bool {
            let trimmedTitle = viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedDesc = viewModel.description.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmedTitle.isEmpty || !trimmedDesc.isEmpty
        }
        
        /// If the form has unsaved work, shows a confirmation dialog. Otherwise runs the action immediately.
        private func guardDirtyForm(action: @escaping () -> Void) {
            if hasUnsavedWork {
                pendingAction = action
                showDirtyFormAlert = true
            } else {
                action()
            }
        }

        private func deleteAllCards() {
            do {
                try modelContext.delete(model: Card.self)
            } catch {
                errorAlert = ErrorAlert(message: "Failed to delete items: \(error.localizedDescription)")
            }
        }
        
        // Optional: If you wanted the "Delete Unsorted" feature we discussed earlier
        private func deleteUnsortedCards() {
            do {
                let descriptor = FetchDescriptor<Card>()
                let allCards = try modelContext.fetch(descriptor)
                for card in allCards {
                    if card.collection == nil {
                        modelContext.delete(card)
                    }
                }
            } catch {
                errorAlert = ErrorAlert(message: "Failed to clean up: \(error.localizedDescription)")
            }
        }
}

// MARK: - Supporting Views
// TODO: Extract these into their own files (Components/ModernCard.swift, Components/ModernTextField.swift)

struct ModernCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
