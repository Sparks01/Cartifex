import Foundation
import SwiftUI

@Observable
class CatalogDataStore {
    static let shared = CatalogDataStore()
    
    // MARK: - All Data (Cached)
    var allWeapons: [Card] = []
    var allArmor: [Card] = []
    var allMagicItems: [Card] = []
    var allSpells: [Open5eItem] = []
    
    // MARK: - Loading State
    var isLoading = false
    var loadProgress: String = ""
    var lastLoadDate: Date?
    var hasLoadedOnce = false
    
    private init() {}
    
    // MARK: - File Paths
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var weaponsFileURL: URL {
        documentsDirectory.appendingPathComponent("catalog_weapons.json")
    }
    
    private var armorFileURL: URL {
        documentsDirectory.appendingPathComponent("catalog_armor.json")
    }
    
    private var magicItemsFileURL: URL {
        documentsDirectory.appendingPathComponent("catalog_magic_items.json")
    }
    
    private var spellsFileURL: URL {
        documentsDirectory.appendingPathComponent("catalog_spells.json")
    }
    
    private var metadataFileURL: URL {
        documentsDirectory.appendingPathComponent("catalog_metadata.json")
    }
    
    // MARK: - Load from Disk (Fast)
    
    func loadFromDisk() {
        print("📂 Loading catalog from disk...")
        
        // Load metadata
        if let metadata = loadMetadata() {
            lastLoadDate = metadata.lastLoadDate
            print("   Last loaded: \(metadata.lastLoadDate)")
        }
        
        // Load each catalog (convert from CodableCard to Card)
        if let codableWeapons = loadFromFile(weaponsFileURL, as: [CodableCard].self) {
            allWeapons = codableWeapons.map { $0.toCard() }
            print("   ✅ Loaded \(allWeapons.count) weapons from disk")
        }
        
        if let codableArmor = loadFromFile(armorFileURL, as: [CodableCard].self) {
            allArmor = codableArmor.map { $0.toCard() }
            print("   ✅ Loaded \(allArmor.count) armor from disk")
        }
        
        if let codableMagicItems = loadFromFile(magicItemsFileURL, as: [CodableCard].self) {
            allMagicItems = codableMagicItems.map { $0.toCard() }
            print("   ✅ Loaded \(allMagicItems.count) magic items from disk")
        }
        
        if let spells = loadFromFile(spellsFileURL, as: [Open5eItem].self) {
            allSpells = spells
            print("   ✅ Loaded \(spells.count) spells from disk")
        }
        
        hasLoadedOnce = !allWeapons.isEmpty || !allArmor.isEmpty || !allMagicItems.isEmpty || !allSpells.isEmpty
        
        if hasLoadedOnce {
            print("📂 Disk load complete!")
        } else {
            print("📂 No cached data found on disk")
        }
    }
    
    // MARK: - Load from API (Slow)
    
    @MainActor
    func loadAllDataFromAPI(forceRefresh: Bool = false) async {
        // If already loaded and not forcing refresh, skip
        if hasLoadedOnce && !forceRefresh {
            print("📦 Catalog already loaded, skipping API fetch")
            return
        }
        
        guard !isLoading else {
            print("⚠️ Already loading, skipping duplicate request")
            return
        }
        
        isLoading = true
        loadProgress = "Starting..."
        
        print("🌐 Loading catalog from API...")
        
        do {
            // Load all sources first (without filtering)
            Open5eService.shared.selectedSourceKey = nil
            
            // 1. Weapons (mundane + magic)
            loadProgress = "Loading weapons..."
            async let mundaneWeapons = Open5eService.shared.fetchWeaponsAsCards()
            async let allMagicItemsForWeapons = Open5eService.shared.fetchMagicItemsAsCards()
            let (mundane, allMagic1) = try await (mundaneWeapons, allMagicItemsForWeapons)
            let magicWeapons = allMagic1.filter { $0.category == .weapon }
            allWeapons = deduplicateCards(mundane + magicWeapons)
            print("   ✅ Loaded \(allWeapons.count) weapons")
            
            // 2. Armor (mundane + magic)
            loadProgress = "Loading armor..."
            async let mundaneArmor = Open5eService.shared.fetchArmorAsCards()
            async let allMagicItemsForArmor = Open5eService.shared.fetchMagicItemsAsCards()
            let (mundaneArm, allMagic2) = try await (mundaneArmor, allMagicItemsForArmor)
            let magicArmor = allMagic2.filter { $0.category == .armor }
            allArmor = deduplicateCards(mundaneArm + magicArmor)
            print("   ✅ Loaded \(allArmor.count) armor")
            
            // 3. Magic Items (excluding weapons/armor)
            loadProgress = "Loading magic items..."
            let allMagic3 = try await Open5eService.shared.fetchMagicItemsAsCards()
            allMagicItems = deduplicateCards(allMagic3.filter { $0.category != .weapon && $0.category != .armor })
            print("   ✅ Loaded \(allMagicItems.count) magic items")
            
            // 4. Spells
            loadProgress = "Loading spells..."
            let rawSpells = try await Open5eService.shared.fetchSpells()
            allSpells = deduplicateOpen5eItems(rawSpells)
            print("   ✅ Loaded \(allSpells.count) spells")
            
            // Save to disk
            loadProgress = "Saving to disk..."
            saveToDisk()
            
            lastLoadDate = Date()
            hasLoadedOnce = true
            loadProgress = "Complete!"
            
            print("🌐 API load complete!")
            
        } catch {
            print("❌ Failed to load catalog: \(error)")
            loadProgress = "Error: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Save to Disk
    
    private func saveToDisk() {
        print("💾 Saving catalog to disk...")
        
        // Convert Card to CodableCard before saving
        let codableWeapons = allWeapons.map { CodableCard.from($0) }
        let codableArmor = allArmor.map { CodableCard.from($0) }
        let codableMagicItems = allMagicItems.map { CodableCard.from($0) }
        
        saveToFile(codableWeapons, to: weaponsFileURL)
        saveToFile(codableArmor, to: armorFileURL)
        saveToFile(codableMagicItems, to: magicItemsFileURL)
        saveToFile(allSpells, to: spellsFileURL)
        
        // Save metadata
        let metadata = CatalogMetadata(lastLoadDate: Date())
        saveToFile(metadata, to: metadataFileURL)
        
        print("💾 Save complete!")
    }
    
    // MARK: - File I/O Helpers
    
    private func saveToFile<T: Encodable>(_ data: T, to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            try jsonData.write(to: url)
        } catch {
            print("❌ Failed to save to \(url.lastPathComponent): \(error)")
        }
    }
    
    private func loadFromFile<T: Decodable>(_ url: URL, as type: T.Type) -> T? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Failed to load from \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    private func loadMetadata() -> CatalogMetadata? {
        loadFromFile(metadataFileURL, as: CatalogMetadata.self)
    }
    
    // MARK: - Filtered Data (for Catalog View)
    
    func filteredWeapons(source: String?, search: String) -> [Card] {
        filter(allWeapons, source: source, search: search)
    }
    
    func filteredArmor(source: String?, search: String) -> [Card] {
        filter(allArmor, source: source, search: search)
    }
    
    func filteredMagicItems(source: String?, search: String, category: String?, rarity: String?) -> [Card] {
        var filtered = filter(allMagicItems, source: source, search: search)
        
        // Apply category filter
        if let category = category {
            filtered = filtered.filter { card in
                card.magicItemDetails?.type.localizedCaseInsensitiveContains(category) ?? false
            }
        }
        
        // Apply rarity filter
        if let rarity = rarity {
            filtered = filtered.filter { card in
                card.magicItemDetails?.rarity.localizedCaseInsensitiveContains(rarity) ?? false
            }
        }
        
        return filtered
    }
    
    func filteredSpells(source: String?, search: String, spellClass: String? = nil) -> [Open5eItem] {
        var filtered = allSpells
        
        // Source filter
        if let source = source {
            filtered = filtered.filter { spell in
                spell.document_title?.contains(source) ?? false ||
                spell.document_title?.lowercased().contains(sourceKeyToTitle(source).lowercased()) ?? false
            }
        }
        
        // Search filter
        if !search.isEmpty {
            let searchLower = search.lowercased()
            filtered = filtered.filter { spell in
                spell.name?.lowercased().contains(searchLower) ?? false ||
                spell.desc?.lowercased().contains(searchLower) ?? false ||
                spell.school?.lowercased().contains(searchLower) ?? false
            }
        }
        
        // Class filter (classes field is comma-separated, e.g. "Wizard, Sorcerer, Warlock")
        if let spellClass = spellClass {
            let classLower = spellClass.lowercased()
            filtered = filtered.filter { spell in
                spell.classes?.lowercased().contains(classLower) ?? false
            }
        }
        
        return filtered
    }
    
    private func filter(_ cards: [Card], source: String?, search: String) -> [Card] {
        var filtered = cards
        
        // Source filter
        if let source = source {
            let sourceTitle = sourceKeyToTitle(source)
            filtered = filtered.filter { card in
                card.source.contains(sourceTitle)
            }
        }
        
        // Search filter
        if !search.isEmpty {
            let searchLower = search.lowercased()
            filtered = filtered.filter { card in
                card.title.lowercased().contains(searchLower) ||
                card.subtitle.lowercased().contains(searchLower) ||
                card.itemDescription.lowercased().contains(searchLower)
            }
        }
        
        return filtered
    }
    
    private func sourceKeyToTitle(_ key: String) -> String {
        switch key {
        case "srd-2024": return "System Reference Document 5.2"
        case "srd-2014": return "System Reference Document 5.1"
        default: return key
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
    
    // MARK: - Clear Cache
    
    func clearCache() {
        print("🗑️ Clearing catalog cache...")
        
        try? FileManager.default.removeItem(at: weaponsFileURL)
        try? FileManager.default.removeItem(at: armorFileURL)
        try? FileManager.default.removeItem(at: magicItemsFileURL)
        try? FileManager.default.removeItem(at: spellsFileURL)
        try? FileManager.default.removeItem(at: metadataFileURL)
        
        allWeapons = []
        allArmor = []
        allMagicItems = []
        allSpells = []
        lastLoadDate = nil
        hasLoadedOnce = false
        
        print("🗑️ Cache cleared!")
    }
}

// MARK: - Metadata

struct CatalogMetadata: Codable {
    let lastLoadDate: Date
}
