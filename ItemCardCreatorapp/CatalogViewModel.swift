//
//  CatalogViewModel.swift
//  ItemCardCreatorapp
//
//  Created by Jose Munoz on 1/24/26.
//

import SwiftUI
import Foundation

@Observable
class CatalogViewModel {
    // MARK: - Singleton Cache
    static let shared = CatalogViewModel()
    
    // MARK: - State
    var mode: CatalogMode = .magicItems
    var selectedSource: String? = nil
    var availableSources: [V2Source] = []
    var searchText = ""
    
    var isLoading = false
    var isLoadingSources = false
    
    // Filters (Magic Items)
    var selectedCategory: String? = nil
    var selectedRarity: String? = nil
    
    // MARK: - Cached Data
    private var cachedMagicItems: [Card] = []
    private var cachedWeapons: [Card] = []
    private var cachedArmor: [Card] = []
    private var cachedSpells: [Open5eItem] = []
    
    // Track what's been loaded for each source
    private var loadedSources: Set<String> = []
    
    // Filtered results (exposed to view)
    var displayedCards: [Card] = []
    var displayedSpells: [Open5eItem] = []
    
    enum CatalogMode: String, CaseIterable {
        case magicItems = "Magic Items"
        case spells = "Spells"
        case weapons = "Weapons"
        case armor = "Armor"
    }
    
    private init() {}
    
    // MARK: - Load Sources (Once)
    
    func loadSourcesIfNeeded() async {
        guard availableSources.isEmpty else { return }
        
        isLoadingSources = true
        defer { isLoadingSources = false }
        
        do {
            availableSources = try await Open5eService.shared.fetchAvailableSources()
            
            // Sort: SRD 2024, then SRD 2014, then alphabetically
            availableSources.sort { a, b in
                if a.key == "srd-2024" { return true }
                if b.key == "srd-2024" { return false }
                if a.key == "srd-2014" { return true }
                if b.key == "srd-2014" { return false }
                return a.displayName < b.displayName
            }
            
            // Set default to SRD 2024
            if let srd2024 = availableSources.first(where: { $0.key == "srd-2024" }) {
                selectedSource = srd2024.key
            }
            
            print("✅ CATALOG: Loaded \(availableSources.count) sources")
        } catch {
            print("❌ Failed to load sources: \(error)")
        }
    }
    
    // MARK: - Smart Loading (with Cache)
    
    func loadDataForCurrentMode() async {
        // Build cache key: "mode-source"
        let cacheKey = "\(mode.rawValue)-\(selectedSource ?? "all")"
        
        // Check if we've already loaded this combination
        if loadedSources.contains(cacheKey) && searchText.isEmpty {
            print("📦 CACHE HIT: Using cached data for \(cacheKey)")
            applyFilters()
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Set the source filter in the service
        Open5eService.shared.selectedSourceKey = selectedSource
        
        do {
            switch mode {
            case .magicItems:
                if !loadedSources.contains(cacheKey) || !searchText.isEmpty {
                    let cards = try await Open5eService.shared.fetchMagicItemsAsCards(search: searchText)
                    let filtered = cards.filter { $0.category != .weapon && $0.category != .armor }
                    cachedMagicItems = deduplicateCards(filtered)
                    
                    if searchText.isEmpty {
                        loadedSources.insert(cacheKey)
                    }
                    
                    print("✅ CATALOG: Loaded \(cachedMagicItems.count) magic items")
                }
                applyFilters()
                
            case .weapons:
                if !loadedSources.contains(cacheKey) || !searchText.isEmpty {
                    async let mundaneTask = Open5eService.shared.fetchWeaponsAsCards(search: searchText)
                    async let magicTask = Open5eService.shared.fetchMagicItemsAsCards(search: searchText)
                    let (mundane, allMagic) = try await (mundaneTask, magicTask)
                    let magicWeapons = allMagic.filter { $0.category == .weapon }
                    cachedWeapons = deduplicateCards(mundane + magicWeapons)
                    
                    if searchText.isEmpty {
                        loadedSources.insert(cacheKey)
                    }
                    
                    print("✅ CATALOG: Loaded \(cachedWeapons.count) weapons")
                }
                displayedCards = cachedWeapons
                
            case .armor:
                if !loadedSources.contains(cacheKey) || !searchText.isEmpty {
                    async let mundaneTask = Open5eService.shared.fetchArmorAsCards(search: searchText)
                    async let magicTask = Open5eService.shared.fetchMagicItemsAsCards(search: searchText)
                    let (mundane, allMagic) = try await (mundaneTask, magicTask)
                    let magicArmor = allMagic.filter { $0.category == .armor }
                    cachedArmor = deduplicateCards(mundane + magicArmor)
                    
                    if searchText.isEmpty {
                        loadedSources.insert(cacheKey)
                    }
                    
                    print("✅ CATALOG: Loaded \(cachedArmor.count) armor")
                }
                displayedCards = cachedArmor
                
            case .spells:
                if !loadedSources.contains(cacheKey) || !searchText.isEmpty {
                    let rawResults = try await Open5eService.shared.fetchSpells(search: searchText)
                    cachedSpells = deduplicateOpen5eItems(rawResults)
                    
                    if searchText.isEmpty {
                        loadedSources.insert(cacheKey)
                    }
                    
                    print("✅ CATALOG: Loaded \(cachedSpells.count) spells")
                }
                displayedSpells = cachedSpells
            }
            
        } catch {
            print("❌ CATALOG ERROR: \(error)")
        }
    }
    
    // MARK: - Filtering
    
    func applyFilters() {
        var filtered = cachedMagicItems
        
        if let category = selectedCategory {
            filtered = filtered.filter { card in
                card.magicItemDetails?.type.localizedCaseInsensitiveContains(category) ?? false
            }
        }
        
        if let rarity = selectedRarity {
            filtered = filtered.filter { card in
                card.magicItemDetails?.rarity.localizedCaseInsensitiveContains(rarity) ?? false
            }
        }
        
        displayedCards = filtered
        print("🔍 FILTER: Showing \(displayedCards.count) of \(cachedMagicItems.count) magic items")
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        cachedMagicItems = []
        cachedWeapons = []
        cachedArmor = []
        cachedSpells = []
        loadedSources.removeAll()
        print("🗑️ CACHE CLEARED")
    }
    
    func clearCacheForCurrentSource() {
        let cacheKey = "\(mode.rawValue)-\(selectedSource ?? "all")"
        loadedSources.remove(cacheKey)
        print("🗑️ CACHE CLEARED for \(cacheKey)")
    }
    
    // MARK: - Search
    
    func performSearch() async {
        // Search always fetches fresh data
        await loadDataForCurrentMode()
    }
    
    // MARK: - Source Changed
    
    func sourceChanged() async {
        // When source changes, reload data
        await loadDataForCurrentMode()
    }
    
    // MARK: - Mode Changed
    
    func modeChanged() {
        // Reset filters
        selectedCategory = nil
        selectedRarity = nil
        
        // Check cache - if we have data, use it immediately
        let cacheKey = "\(mode.rawValue)-\(selectedSource ?? "all")"
        if loadedSources.contains(cacheKey) {
            print("📦 INSTANT LOAD: Using cached \(cacheKey)")
            switch mode {
            case .magicItems:
                applyFilters()
            case .weapons:
                displayedCards = cachedWeapons
            case .armor:
                displayedCards = cachedArmor
            case .spells:
                displayedSpells = cachedSpells
            }
        } else {
            // Clear display while loading
            displayedCards = []
            displayedSpells = []
        }
    }
    
    // MARK: - Deduplication
    
    private func deduplicateCards(_ cards: [Card]) -> [Card] {
        var seenNames = Set<String>()
        return cards.filter { card in
            if seenNames.contains(card.title) { return false }
            else { seenNames.insert(card.title); return true }
        }
    }
    
    private func deduplicateOpen5eItems(_ items: [Open5eItem]) -> [Open5eItem] {
        var seenNames = Set<String>()
        return items.filter { item in
            guard let name = item.name else { return false }
            if seenNames.contains(name) { return false }
            else { seenNames.insert(name); return true }
        }
    }
}
