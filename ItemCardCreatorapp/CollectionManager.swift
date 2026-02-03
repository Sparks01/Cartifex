//
//  CollectionManagerView.swift
//  ItemCardCreatorapp
//
//  Created by Claude on 2/1/26.
//

import SwiftUI
import SwiftData

struct CollectionManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CardCollection.name) private var collections: [CardCollection]
    @Query(sort: \Card.title) private var allCards: [Card]
    
    @State private var showNewCollectionSheet = false
    @State private var editingCollection: CardCollection? = nil
    
    // Delete confirmation
    @State private var collectionToDelete: CardCollection? = nil
    @State private var showDeleteConfirm = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Collections")
                    .font(.title2.bold())
                
                Spacer()
                
                Button {
                    showNewCollectionSheet = true
                } label: {
                    Label("New Collection", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Done") { dismiss() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            .padding()
            
            Divider()
            
            if collections.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No Collections")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Create a collection to organize your cards.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(collections) { collection in
                        CollectionRow(
                            collection: collection,
                            cardCount: cardCount(for: collection),
                            onEdit: { editingCollection = collection },
                            onDelete: {
                                collectionToDelete = collection
                                showDeleteConfirm = true
                            }
                        )
                    }
                }
                .listStyle(.inset)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        // New Collection
        .sheet(isPresented: $showNewCollectionSheet) {
            CollectionEditorSheet(mode: .create) { name, icon, colorHex in
                let newCollection = CardCollection(name: name, icon: icon, colorHex: colorHex)
                modelContext.insert(newCollection)
            }
        }
        // Edit Collection
        .sheet(item: $editingCollection) { collection in
            CollectionEditorSheet(
                mode: .edit(name: collection.name, icon: collection.icon, colorHex: collection.colorHex)
            ) { name, icon, colorHex in
                collection.name = name
                collection.icon = icon
                collection.colorHex = colorHex
            }
        }
        // Delete confirmation
        .alert("Delete Collection", isPresented: $showDeleteConfirm, presenting: collectionToDelete) { collection in
            let count = cardCount(for: collection)
            Button("Delete Collection & \(count) Cards", role: .destructive) {
                deleteCollection(collection, keepCards: false)
            }
            Button("Keep Cards, Delete Collection") {
                deleteCollection(collection, keepCards: true)
            }
            Button("Cancel", role: .cancel) { collectionToDelete = nil }
        } message: { collection in
            let count = cardCount(for: collection)
            Text("\"\(collection.name)\" contains \(count) cards. You can delete everything, or keep the cards and move them to the workspace.")
        }
    }
    
    private func cardCount(for collection: CardCollection) -> Int {
        allCards.filter { $0.collection == collection }.count
    }
    
    private func deleteCollection(_ collection: CardCollection, keepCards: Bool) {
        let cardsInCollection = allCards.filter { $0.collection == collection }
        if keepCards {
            for card in cardsInCollection {
                card.collection = nil
            }
        } else {
            for card in cardsInCollection {
                modelContext.delete(card)
            }
        }
        modelContext.delete(collection)
        collectionToDelete = nil
    }
}

// MARK: - Collection Row

private struct CollectionRow: View {
    let collection: CardCollection
    let cardCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with color
            Image(systemName: collection.icon)
                .font(.title3)
                .foregroundColor(Color(hex: collection.colorHex))
                .frame(width: 32, height: 32)
                .background(
                    (Color(hex: collection.colorHex)).opacity(0.15)
                )
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(collection.name)
                    .font(.headline)
                Text("\(cardCount) card\(cardCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Created date
            Text(collection.createdDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button { onEdit() } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .help("Edit Collection")
            
            Button { onDelete() } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.borderless)
            .help("Delete Collection")
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Collection Editor Sheet (Create / Edit)

private struct CollectionEditorSheet: View {
    enum Mode {
        case create
        case edit(name: String, icon: String, colorHex: String)
    }
    
    let mode: Mode
    let onSave: (String, String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var selectedIcon: String = "folder"
    @State private var selectedColorHex: String = "0000FF"
    
    private let iconOptions = [
        "folder", "folder.fill", "book.closed", "scroll",
        "shield", "flame", "wand.and.stars", "leaf",
        "map", "crown", "star", "heart",
        "bolt", "drop", "mountain.2", "building.columns",
        "tent", "flag", "music.note", "puzzlepiece",
        "theatermasks", "dumbbell", "cross.vial", "brain.head.profile"
    ]
    
    private let colorOptions: [(name: String, hex: String)] = [
        ("Blue", "0066FF"),
        ("Purple", "8B5CF6"),
        ("Red", "DC2626"),
        ("Orange", "EA580C"),
        ("Green", "16A34A"),
        ("Teal", "0D9488"),
        ("Pink", "DB2777"),
        ("Indigo", "4F46E5"),
        ("Amber", "D97706"),
        ("Slate", "64748B"),
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text(isEditing ? "Edit Collection" : "New Collection")
                .font(.title3.bold())
            
            // Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Collection name…", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Icon picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Icon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 8), count: 8), spacing: 8) {
                    ForEach(iconOptions, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 16))
                                .frame(width: 32, height: 32)
                                .background(
                                    selectedIcon == icon
                                        ? (Color(hex: selectedColorHex)).opacity(0.2)
                                        : Color.secondary.opacity(0.1)
                                )
                                .foregroundColor(
                                    selectedIcon == icon
                                        ? (Color(hex: selectedColorHex))
                                        : .secondary
                                )
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(selectedIcon == icon ? (Color(hex: selectedColorHex)) : .clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Color picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Color")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ForEach(colorOptions, id: \.hex) { option in
                        Button {
                            selectedColorHex = option.hex
                        } label: {
                            Circle()
                                .fill(Color(hex: option.hex))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColorHex == option.hex ? 2.5 : 0)
                                )
                                .overlay(
                                    selectedColorHex == option.hex
                                        ? Image(systemName: "checkmark")
                                            .font(.caption.bold())
                                            .foregroundColor(.white)
                                        : nil
                                )
                        }
                        .buttonStyle(.plain)
                        .help(option.name)
                    }
                }
            }
            
            // Preview
            HStack(spacing: 8) {
                Image(systemName: selectedIcon)
                    .foregroundColor(Color(hex: selectedColorHex))
                Text(name.isEmpty ? "Collection Name" : name)
                    .foregroundColor(name.isEmpty ? .secondary : .primary)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.08))
            .cornerRadius(8)
            
            Spacer()
            
            // Actions
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button(isEditing ? "Save" : "Create") {
                    onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), selectedIcon, selectedColorHex)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.return, modifiers: .command)
            }
        }
        .padding(24)
        .frame(width: 380, height: 480)
        .onAppear {
            if case .edit(let n, let i, let c) = mode {
                name = n
                selectedIcon = i
                selectedColorHex = c
            }
        }
    }
    
    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }
}
