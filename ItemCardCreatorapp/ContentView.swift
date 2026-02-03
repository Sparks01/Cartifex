import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Card.createdDate, order: .reverse) private var allCards: [Card]
    @Query(sort: \CardCollection.name) private var collections: [CardCollection]
    @Environment(\.modelContext) private var modelContext
    
    @State private var currentLayout: CardLayout = .landscape35x5
    @State private var searchViewModel = SearchViewModel()
    @State private var cardViewModel = CardCreationViewModel()
    @State private var showingExportOptions = false
    @State private var selectedCards: Set<Card.ID> = []
    @State private var isSelectionMode = false
    
    // Delete confirmation
    @State private var cardToDelete: Card? = nil
    @State private var showDeleteConfirm = false
    
    // Dirty form guard for edit
    @State private var showEditDirtyAlert = false
    @State private var pendingEditCard: Card? = nil
    
    // Clear Workspace
    @State private var showClearWorkspaceConfirm = false
    
    // Collection management
    @State private var showClearCollectionConfirm = false
    @State private var collectionToClear: CardCollection? = nil
    @State private var showDeleteCollectionConfirm = false
    @State private var collectionToDelete: CardCollection? = nil
    @State private var showCollectionManager = false
    
    // Performance: Filtered results are now State
    @State private var filteredCards: [Card] = []
    
    // Live Preview
    @State private var showPreview = false
    
    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: cardViewModel)
        } detail: {
            VStack(spacing: 0) {
                toolbarSection
                
                if showPreview {
                    // Live Preview Mode
                    CardPreviewPanel(viewModel: cardViewModel, layout: currentLayout)
                } else {
                    // Grid Mode
                    searchSection
                    
                    ScrollView {
                        if filteredCards.isEmpty && !allCards.isEmpty {
                            emptySearchState
                        } else if allCards.isEmpty {
                            emptyState
                        } else {
                            cardGrid
                        }
                    }
                    .background(Color(NSColor.windowBackgroundColor))
                }
            }
        }
        .onAppear {
            updateSearch()
        }
        // Update filters when data changes
        .onChange(of: allCards) { _, _ in updateSearch() }
        // Performance: Debounce search input
        .onChange(of: searchViewModel.searchText) { _, _ in performSearch() }
        // Immediate updates for filter changes
        .onChange(of: searchViewModel.sortOrder) { _, _ in performSearch(immediate: true) }
        .onChange(of: searchViewModel.selectedCategory) { _, _ in performSearch(immediate: true) }
        .onChange(of: searchViewModel.selectedSource) { _, _ in performSearch(immediate: true) }
        .onChange(of: searchViewModel.selectedTags) { _, _ in performSearch(immediate: true) }
        .onChange(of: searchViewModel.filterCollection) { _, _ in performSearch(immediate: true) }
        .onChange(of: searchViewModel.collectionFilterMode) { _, _ in performSearch(immediate: true) }
        
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView(
                cards: isSelectionMode ? allCards.filter { selectedCards.contains($0.id) } : filteredCards,
                layout: currentLayout
            )
        }
        .sheet(isPresented: $showCollectionManager) {
            CollectionManagerView()
        }
        .modifier(ContentViewAlerts(
            showDeleteConfirm: $showDeleteConfirm,
            cardToDelete: $cardToDelete,
            showEditDirtyAlert: $showEditDirtyAlert,
            pendingEditCard: $pendingEditCard,
            showClearWorkspaceConfirm: $showClearWorkspaceConfirm,
            showClearCollectionConfirm: $showClearCollectionConfirm,
            collectionToClear: $collectionToClear,
            showDeleteCollectionConfirm: $showDeleteCollectionConfirm,
            collectionToDelete: $collectionToDelete,
            modelContext: modelContext,
            selectedCards: $selectedCards,
            cardViewModel: cardViewModel,
            allCards: allCards,
            clearWorkspace: clearWorkspace,
            deleteCardsInCollection: deleteCardsInCollection,
            deleteCollection: deleteCollection
        ))
    }
    
    // MARK: - Logic
    
    private func updateSearch() {
        searchViewModel.updateAvailableFilters(from: allCards)
        filteredCards = searchViewModel.filteredAndSortedCards(allCards)
    }
    
    private func performSearch(immediate: Bool = false) {
        Task {
            if !immediate {
                try? await Task.sleep(nanoseconds: 200 * 1_000_000)
            }
            if Task.isCancelled { return }
            
            let results = searchViewModel.filteredAndSortedCards(allCards)
            await MainActor.run { self.filteredCards = results }
        }
    }
    
    // Move Cards Logic
    private func moveCards(_ cardsToMove: [Card], to collection: CardCollection?) {
        for card in cardsToMove {
            card.collection = collection
        }
        
        // Refresh view
        updateSearch()
        
        // Exit selection mode if active
        if isSelectionMode {
            selectedCards.removeAll()
            isSelectionMode = false
        }
    }
    
    // MARK: - Toolbar
    private var toolbarSection: some View {
        HStack(spacing: 16) {
            HStack(spacing: 8) {
                Text("Layout:")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $currentLayout) {
                    ForEach(CardLayout.allCases, id: \.self) { layout in
                        Text(layout.rawValue).tag(layout)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)
            }
            
            // Preview toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPreview.toggle()
                }
            } label: {
                Label(showPreview ? "Grid" : "Preview",
                      systemImage: showPreview ? "square.grid.2x2" : "eye")
            }
            .buttonStyle(.bordered)
            .tint(showPreview ? .accentColor : nil)
            .keyboardShortcut("l", modifiers: .command)
            
            Spacer()
            
            HStack(spacing: 12) {
                
                // CLEAR WORKSPACE / CLEAR COLLECTION — context-aware
                if !filteredCards.isEmpty && !isSelectionMode {
                    if searchViewModel.collectionFilterMode == .workspace {
                        Button {
                            showClearWorkspaceConfirm = true
                        } label: {
                            Label("Clear Workspace", systemImage: "xmark.bin")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } else if searchViewModel.collectionFilterMode == .specific, let collection = searchViewModel.filterCollection {
                        Menu {
                            Button(role: .destructive) {
                                collectionToClear = collection
                                showClearCollectionConfirm = true
                            } label: {
                                Label("Delete All Cards in \"\(collection.name)\"", systemImage: "trash")
                            }
                            
                            Button {
                                uncollectAllInCollection(collection)
                            } label: {
                                Label("Move All to Workspace", systemImage: "tray.and.arrow.up")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                collectionToDelete = collection
                                showDeleteCollectionConfirm = true
                            } label: {
                                Label("Delete Collection \"\(collection.name)\"…", systemImage: "folder.badge.minus")
                            }
                        } label: {
                            Label("Manage", systemImage: "ellipsis.circle")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // BATCH MOVE BUTTON (Only visible when items are selected)
                if isSelectionMode && !selectedCards.isEmpty {
                    Menu {
                        Text("Move \(selectedCards.count) items to...")
                        Button("Library (No Collection)") {
                            let cardsToMove = allCards.filter { selectedCards.contains($0.id) }
                            moveCards(cardsToMove, to: nil)
                        }
                        Divider()
                        ForEach(collections) { collection in
                            Button {
                                let cardsToMove = allCards.filter { selectedCards.contains($0.id) }
                                moveCards(cardsToMove, to: collection)
                            } label: {
                                Label(collection.name, systemImage: collection.icon)
                            }
                        }
                    } label: {
                        Label("Move", systemImage: "folder")
                    }
                    .menuStyle(.borderedButton)
                }
                
                if !filteredCards.isEmpty {
                    Button {
                        isSelectionMode.toggle()
                        if !isSelectionMode { selectedCards.removeAll() }
                    } label: {
                        Label(isSelectionMode ? "Done" : "Select",
                              systemImage: isSelectionMode ? "checkmark" : "checkmark.circle")
                    }
                    .buttonStyle(.bordered)
                }
                
                if !filteredCards.isEmpty {
                    Button {
                        showingExportOptions = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut("p", modifiers: .command)
                }
                
                Text(countText)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.2)), alignment: .bottom)
    }
    
    // MARK: - Search & Filters
    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search cards...", text: $searchViewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                
                if searchViewModel.hasActiveFilters {
                    Button("Clear") {
                        searchViewModel.clearFilters()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            if !searchViewModel.availableSources.isEmpty || !searchViewModel.availableTags.isEmpty || !collections.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        
                        // COLLECTION / WORKSPACE FILTER
                        Menu {
                            Button {
                                searchViewModel.collectionFilterMode = .workspace
                                searchViewModel.filterCollection = nil
                            } label: {
                                Label("Workspace", systemImage: "hammer")
                            }
                            
                            Button {
                                searchViewModel.collectionFilterMode = .all
                                searchViewModel.filterCollection = nil
                            } label: {
                                Label("All Cards", systemImage: "tray.full")
                            }
                            
                            if !collections.isEmpty {
                                Divider()
                                ForEach(collections) { collection in
                                    Button {
                                        searchViewModel.collectionFilterMode = .specific
                                        searchViewModel.filterCollection = collection
                                    } label: {
                                        Label(collection.name, systemImage: collection.icon)
                                    }
                                }
                            }
                            
                            Divider()
                            
                            Button {
                                showCollectionManager = true
                            } label: {
                                Label("Manage Collections…", systemImage: "gearshape")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: collectionFilterIcon)
                                Text(collectionFilterLabel)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(searchViewModel.collectionFilterMode != .workspace ? Color.accentColor : Color.secondary.opacity(0.2))
                            .foregroundColor(searchViewModel.collectionFilterMode != .workspace ? .white : .secondary)
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                        
                        // CATEGORY FILTER
                        Menu {
                            Button("All Categories") { searchViewModel.selectedCategory = nil }
                            Divider()
                            ForEach(CardCategory.allCases, id: \.self) { category in
                                Button(category.rawValue) {
                                    searchViewModel.selectedCategory =
                                        searchViewModel.selectedCategory == category ? nil : category
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "square.grid.2x2")
                                Text(searchViewModel.selectedCategory?.rawValue ?? "Category")
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(searchViewModel.selectedCategory != nil ? Color.accentColor : Color.secondary.opacity(0.2))
                            .foregroundColor(searchViewModel.selectedCategory != nil ? .white : .secondary)
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                        
                        // SORT
                        Menu {
                            ForEach(SearchViewModel.SortOrder.allCases, id: \.self) { order in
                                Button { searchViewModel.sortOrder = order } label: {
                                    Label(order.rawValue, systemImage: order.systemImage)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: searchViewModel.sortOrder.systemImage)
                                Text(searchViewModel.sortOrder.rawValue)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.2))
                            .foregroundColor(.secondary)
                            .cornerRadius(16)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Grid
    private var cardGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: currentLayout.width))], spacing: 30) {
            ForEach(filteredCards) { card in
                let processed = CardProcessor.process(card, layout: currentLayout)
                
                VStack(spacing: 10) {
                    ForEach(processed.pages) { page in
                        ZStack {
                            ItemCardView(page: page, card: card, layout: currentLayout)
                                .contextMenu {
                                    Button {
                                        editCardSafely(card)
                                    } label: {
                                        Label("Edit Card", systemImage: "pencil")
                                    }
                                    
                                    Divider()
                                    
                                    // Move Individual Card
                                    Menu("Move to Collection...") {
                                        Button("Workspace (No Collection)") {
                                            moveCards([card], to: nil)
                                        }
                                        Divider()
                                        ForEach(collections) { collection in
                                            Button(collection.name) {
                                                moveCards([card], to: collection)
                                            }
                                        }
                                    }
                                    
                                    // Remove from collection (only when card is in one)
                                    if card.collection != nil {
                                        Button {
                                            moveCards([card], to: nil)
                                        } label: {
                                            Label("Remove from Collection", systemImage: "folder.badge.minus")
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    Button(role: .destructive) {
                                        confirmDelete(card)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            
                            if isSelectionMode {
                                VStack {
                                    HStack {
                                        Button {
                                            toggleSelection(for: card)
                                        } label: {
                                            Image(systemName: selectedCards.contains(card.id) ?
                                                  "checkmark.circle.fill" : "circle")
                                                .font(.title2)
                                                .foregroundColor(selectedCards.contains(card.id) ?
                                                               .green : .secondary)
                                        }
                                        .buttonStyle(.plain)
                                        .background(Color.white.opacity(0.8))
                                        .clipShape(Circle())
                                        
                                        Spacer()
                                    }
                                    Spacer()
                                }
                                .padding(8)
                            }
                        }
                    }
                    
                    if !isSelectionMode {
                        HStack(spacing: 12) {
                            Button {
                                editCardSafely(card)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.accentColor)
                            .opacity(0.7)
                            
                            Button(role: .destructive) {
                                confirmDelete(card)
                            } label: {
                                Label("Remove", systemImage: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.red)
                            .opacity(0.6)
                        }
                    }
                }
            }
        }
        .padding(30)
    }
    
    // MARK: - Helpers
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.portrait.on.rectangle.portrait.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            Text("Workspace is Empty")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Use the sidebar to create a new card or browse the catalog.\nCards you create appear here until you file them into a collection.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            Text("No Results Found")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("Try adjusting your search terms or filters.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Clear Filters") {
                searchViewModel.clearFilters()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    private var countText: String {
        if isSelectionMode && !selectedCards.isEmpty {
            return "\(selectedCards.count) selected"
        } else if searchViewModel.hasActiveFilters || searchViewModel.collectionFilterMode != .workspace {
            return "\(filteredCards.count) of \(allCards.count)"
        } else {
            return "\(filteredCards.count) Cards"
        }
    }
    
    private func confirmDelete(_ card: Card) {
        cardToDelete = card
        showDeleteConfirm = true
    }
    
    /// If the sidebar form has unsaved work, warn before loading a card for editing.
    private func editCardSafely(_ card: Card) {
        let formHasWork = !cardViewModel.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          !cardViewModel.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        // If we're already editing this same card, just ignore
        if cardViewModel.editingCard?.id == card.id { return }
        
        if formHasWork {
            pendingEditCard = card
            showEditDirtyAlert = true
        } else {
            cardViewModel.loadFromCard(card)
        }
    }
    
    private func toggleSelection(for card: Card) {
        if selectedCards.contains(card.id) {
            selectedCards.remove(card.id)
        } else {
            selectedCards.insert(card.id)
        }
    }
    
    // MARK: - Workspace Helpers
    
    /// All cards not in any collection
    private var uncollectedCards: [Card] {
        allCards.filter { $0.collection == nil }
    }
    
    private func clearWorkspace() {
        for card in uncollectedCards {
            modelContext.delete(card)
        }
        selectedCards.removeAll()
        if isSelectionMode { isSelectionMode = false }
    }
    
    private func deleteCardsInCollection(_ collection: CardCollection) {
        let cardsInCollection = allCards.filter { $0.collection == collection }
        for card in cardsInCollection {
            modelContext.delete(card)
        }
        selectedCards.removeAll()
    }
    
    private func uncollectAllInCollection(_ collection: CardCollection) {
        let cardsInCollection = allCards.filter { $0.collection == collection }
        for card in cardsInCollection {
            card.collection = nil
        }
        // Switch to workspace so user can see where the cards went
        searchViewModel.collectionFilterMode = .workspace
        searchViewModel.filterCollection = nil
        updateSearch()
    }
    
    private func deleteCollection(_ collection: CardCollection, keepCards: Bool) {
        if keepCards {
            // Move cards to workspace first
            let cardsInCollection = allCards.filter { $0.collection == collection }
            for card in cardsInCollection {
                card.collection = nil
            }
        } else {
            // Delete all cards in the collection
            let cardsInCollection = allCards.filter { $0.collection == collection }
            for card in cardsInCollection {
                modelContext.delete(card)
            }
        }
        // Delete the collection itself
        modelContext.delete(collection)
        // Switch back to workspace
        searchViewModel.collectionFilterMode = .workspace
        searchViewModel.filterCollection = nil
        selectedCards.removeAll()
        updateSearch()
    }
    
    // MARK: - Collection Filter Helpers
    
    private var collectionFilterLabel: String {
        switch searchViewModel.collectionFilterMode {
        case .workspace: return "Workspace"
        case .all: return "All Cards"
        case .specific: return searchViewModel.filterCollection?.name ?? "Collection"
        }
    }
    
    private var collectionFilterIcon: String {
        switch searchViewModel.collectionFilterMode {
        case .workspace: return "hammer"
        case .all: return "tray.full"
        case .specific: return "folder"
        }
    }
}

// MARK: - Alerts Modifier (extracted to help Swift type-checker)

struct ContentViewAlerts: ViewModifier {
    @Binding var showDeleteConfirm: Bool
    @Binding var cardToDelete: Card?
    @Binding var showEditDirtyAlert: Bool
    @Binding var pendingEditCard: Card?
    @Binding var showClearWorkspaceConfirm: Bool
    @Binding var showClearCollectionConfirm: Bool
    @Binding var collectionToClear: CardCollection?
    @Binding var showDeleteCollectionConfirm: Bool
    @Binding var collectionToDelete: CardCollection?
    
    let modelContext: ModelContext
    @Binding var selectedCards: Set<Card.ID>
    let cardViewModel: CardCreationViewModel
    let allCards: [Card]
    
    let clearWorkspace: () -> Void
    let deleteCardsInCollection: (CardCollection) -> Void
    let deleteCollection: (CardCollection, Bool) -> Void
    
    private var uncollectedCount: Int {
        allCards.filter { $0.collection == nil }.count
    }
    
    func body(content: Content) -> some View {
        content
            // Delete single card
            .alert("Delete Card", isPresented: $showDeleteConfirm, presenting: cardToDelete) { card in
                Button("Delete", role: .destructive) {
                    modelContext.delete(card)
                    selectedCards.remove(card.id)
                    cardToDelete = nil
                }
                Button("Cancel", role: .cancel) { cardToDelete = nil }
            } message: { card in
                Text("Delete \"\(card.title)\"? This action cannot be undone.")
            }
            // Dirty form warning
            .alert("Unsaved Changes", isPresented: $showEditDirtyAlert) {
                Button("Discard", role: .destructive) {
                    if let card = pendingEditCard {
                        cardViewModel.loadFromCard(card)
                        pendingEditCard = nil
                    }
                }
                Button("Cancel", role: .cancel) { pendingEditCard = nil }
            } message: {
                Text("You have unsaved changes in the form. Discard them to edit this card?")
            }
            // Clear Workspace
            .alert("Clear Workspace", isPresented: $showClearWorkspaceConfirm) {
                Button("Clear \(uncollectedCount) Cards", role: .destructive) {
                    clearWorkspace()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Delete all \(uncollectedCount) uncollected cards from the workspace? Cards in collections are not affected.")
            }
            // Clear Collection
            .alert("Delete Cards", isPresented: $showClearCollectionConfirm, presenting: collectionToClear) { collection in
                Button("Delete All", role: .destructive) {
                    deleteCardsInCollection(collection)
                    collectionToClear = nil
                }
                Button("Cancel", role: .cancel) { collectionToClear = nil }
            } message: { collection in
                let count = allCards.filter { $0.collection == collection }.count
                Text("Delete all \(count) cards in \"\(collection.name)\"? This cannot be undone.")
            }
            // Delete Collection
            .alert("Delete Collection", isPresented: $showDeleteCollectionConfirm, presenting: collectionToDelete) { collection in
                Button("Delete Collection & Cards", role: .destructive) {
                    deleteCollection(collection, false)
                    collectionToDelete = nil
                }
                Button("Keep Cards, Delete Collection") {
                    deleteCollection(collection, true)
                    collectionToDelete = nil
                }
                Button("Cancel", role: .cancel) { collectionToDelete = nil }
            } message: { collection in
                let count = allCards.filter { $0.collection == collection }.count
                Text("\"\(collection.name)\" contains \(count) cards. Delete everything or keep the cards in the workspace.")
            }
    }
}
