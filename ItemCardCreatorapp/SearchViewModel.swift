import SwiftUI
import SwiftData

@Observable
class SearchViewModel {
    var searchText: String = ""
    var selectedCategory: CardCategory?
    var selectedSource: String?
    var selectedTags: Set<String> = []
    
    // Collection / Workspace Filter
    enum CollectionFilterMode: Equatable {
        case workspace   // Uncollected cards only (DEFAULT)
        case all         // Every card regardless of collection
        case specific    // Cards in a specific collection
    }
    
    var collectionFilterMode: CollectionFilterMode = .workspace
    var filterCollection: CardCollection? = nil
    
    var sortOrder: SortOrder = .newest
    
    // Available filter options
    var availableSources: [String] = []
    var availableTags: [String] = []
    
    enum SortOrder: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case alphabetical = "A-Z"
        case reverseAlphabetical = "Z-A"
        case category = "Category"
        
        var systemImage: String {
            switch self {
            case .newest: return "clock"
            case .oldest: return "clock.arrow.circlepath"
            case .alphabetical: return "textformat.abc"
            case .reverseAlphabetical: return "textformat.abc.dottedunderline"
            case .category: return "square.grid.2x2"
            }
        }
    }
    
    func updateAvailableFilters(from cards: [Card]) {
        availableSources = Array(Set(cards.map(\.source))).sorted()
        availableTags = Array(Set(cards.flatMap(\.tags))).sorted()
    }
    
    func filteredAndSortedCards(_ cards: [Card]) -> [Card] {
        var filtered = cards
        
        // 1. Filter by Search Text
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filtered = filtered.filter { card in
                fuzzyMatch(searchText: searchText.lowercased(), in: card)
            }
        }
        
        // 2. Filter by Collection / Workspace
        switch collectionFilterMode {
        case .workspace:
            filtered = filtered.filter { $0.collection == nil }
        case .specific:
            if let collection = filterCollection {
                filtered = filtered.filter { $0.collection == collection }
            }
        case .all:
            break // Show everything
        }
        
        // 3. Filter by Category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // 4. Filter by Source
        if let source = selectedSource {
            filtered = filtered.filter { $0.source == source }
        }
        
        // 5. Filter by Tags
        if !selectedTags.isEmpty {
            filtered = filtered.filter { card in
                !Set(card.tags).intersection(selectedTags).isEmpty
            }
        }
        
        // 6. Apply Sorting
        if !searchText.isEmpty {
            // Relevance Sorting when searching
            let lowerQuery = searchText.lowercased()
            filtered.sort { a, b in
                let aTitle = a.title.lowercased()
                let bTitle = b.title.lowercased()
                
                if aTitle == lowerQuery && bTitle != lowerQuery { return true }
                if bTitle == lowerQuery && aTitle != lowerQuery { return false }
                
                let aStarts = aTitle.hasPrefix(lowerQuery)
                let bStarts = bTitle.hasPrefix(lowerQuery)
                if aStarts && !bStarts { return true }
                if bStarts && !aStarts { return false }
                
                let aContains = aTitle.contains(lowerQuery)
                let bContains = bTitle.contains(lowerQuery)
                if aContains && !bContains { return true }
                if bContains && !aContains { return false }
                
                return a.createdDate > b.createdDate
            }
        } else {
            // Standard Sorting
            switch sortOrder {
            case .newest:
                filtered.sort { $0.createdDate > $1.createdDate }
            case .oldest:
                filtered.sort { $0.createdDate < $1.createdDate }
            case .alphabetical:
                filtered.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            case .reverseAlphabetical:
                filtered.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
            case .category:
                filtered.sort {
                    if $0.category == $1.category {
                        return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                    }
                    return $0.category.rawValue.localizedCaseInsensitiveCompare($1.category.rawValue) == .orderedAscending
                }
            }
        }
        
        return filtered
    }
    
    private func fuzzyMatch(searchText: String, in card: Card) -> Bool {
        let searchTerms = searchText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        guard !searchTerms.isEmpty else { return true }
        
        var detailsContent = ""
        if let spell = card.spellDetails { detailsContent += "\(spell.level) \(spell.school) \(spell.classes) " }
        if let weapon = card.weaponDetails { detailsContent += "\(weapon.damageType) \(weapon.mastery ?? "") " }
        if let magic = card.magicItemDetails { detailsContent += "\(magic.type) \(magic.rarity) " }
        if let npc = card.npcDetails { detailsContent += "\(npc.type) \(npc.role ?? "") \(npc.archetype ?? "") " }
        if let loc = card.locationDetails { detailsContent += "\(loc.type) " }
        if let armor = card.armorDetails { detailsContent += "\(armor.category) " }
        
        let searchableContent = [
            card.title.lowercased(),
            card.subtitle.lowercased(),
            card.tags.joined(separator: " ").lowercased(),
            detailsContent.lowercased(),
            card.itemDescription.lowercased()
        ].joined(separator: " ")
        
        return searchTerms.allSatisfy { term in searchableContent.contains(term) }
    }
    
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
        selectedSource = nil
        selectedTags.removeAll()
        collectionFilterMode = .workspace
        filterCollection = nil
    }
    
    var hasActiveFilters: Bool {
        !searchText.isEmpty ||
        selectedCategory != nil ||
        selectedSource != nil ||
        !selectedTags.isEmpty ||
        collectionFilterMode != .workspace // .all or .specific count as active
    }
}
