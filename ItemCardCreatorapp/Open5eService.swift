import Foundation

class Open5eService {
    static let shared = Open5eService()
    
    // Source filter (stores the document key, e.g., "srd-2024", "srd-2014")
    var selectedSourceKey: String? = nil
    
    private init() {}
    
    // MARK: - Helper for Building URLs
    
    private func buildURL(base: String, search: String, additionalParams: [String] = []) -> URL? {
        var urlString = "\(base)?limit=5000&ordering=name"
        
        // Add source filter using document__slug (this works for V2 API)
        if let sourceKey = selectedSourceKey {
            urlString += "&document__slug=\(sourceKey)"
        }
        
        // Add additional parameters
        for param in additionalParams {
            urlString += "&\(param)"
        }
        
        // Add search query
        if !search.isEmpty {
            if let encoded = search.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                urlString += "&search=\(encoded)"
            }
        }
        
        return URL(string: urlString)
    }
    
    // MARK: - Magic Items
    
    func fetchMagicItemsAsCards(search: String = "", typeFilter: String? = nil) async throws -> [Card] {
        let baseURL = "https://api.open5e.com/v2/items/"
        
        var additionalParams: [String] = []
        
        // Type filter
        if let type = typeFilter {
            if type == "Weapon" {
                additionalParams.append("category__name=Weapon")
            } else if type == "Armor" {
                additionalParams.append("category__name=Armor")
            } else {
                additionalParams.append("type=\(type)")
            }
        }
        
        guard let url = buildURL(base: baseURL, search: search, additionalParams: additionalParams) else {
            return []
        }
        
        print("🔗 MAGIC ITEMS URL: \(url.absoluteString)")
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(V2MagicItemsResponse.self, from: data)
            let cards = response.results.map { Open5eV2Transformer.transformMagicItemToCard($0) }
            
            print("✅ V2 MAGIC ITEMS: Fetched \(cards.count) items")
            if let sourceKey = selectedSourceKey {
                print("   📌 Filter: \(sourceKey)")
            }
            
            return cards
        } catch {
            print("❌ API ERROR (Magic Items): \(error)")
            return []
        }
    }
    
    // MARK: - Weapons
    
    func fetchWeaponsAsCards(search: String = "") async throws -> [Card] {
        let baseURL = "https://api.open5e.com/v2/weapons/"
        
        guard let url = buildURL(base: baseURL, search: search) else {
            return []
        }
        
        print("🔗 WEAPONS URL: \(url.absoluteString)")
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(V2WeaponsResponse.self, from: data)
            let cards = response.results.map { Open5eV2Transformer.transformWeaponToCard($0) }
            
            print("✅ V2 WEAPONS: Fetched \(cards.count) weapons")
            if let sourceKey = selectedSourceKey {
                print("   📌 Filter: \(sourceKey)")
            }
            
            return cards
        } catch {
            print("❌ API ERROR (Weapons): \(error)")
            return []
        }
    }
    
    // MARK: - Armor
    
    func fetchArmorAsCards(search: String = "") async throws -> [Card] {
        let baseURL = "https://api.open5e.com/v2/armor/"
        
        guard let url = buildURL(base: baseURL, search: search) else {
            return []
        }
        
        print("🔗 ARMOR URL: \(url.absoluteString)")
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(V2ArmorResponse.self, from: data)
            let cards = response.results.map { Open5eV2Transformer.transformArmorToCard($0) }
            
            print("✅ V2 ARMOR: Fetched \(cards.count) armor")
            if let sourceKey = selectedSourceKey {
                print("   📌 Filter: \(sourceKey)")
            }
            
            return cards
        } catch {
            print("❌ API ERROR (Armor): \(error)")
            return []
        }
    }
    
    // MARK: - Spells
    
    func fetchSpells(search: String = "") async throws -> [Open5eItem] {
        let baseURL = "https://api.open5e.com/v2/spells/"
        
        guard let url = buildURL(base: baseURL, search: search) else {
            return []
        }
        
        print("🔗 SPELLS URL: \(url.absoluteString)")
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(V2SpellsResponse.self, from: data)
            let spells = response.results.map { Open5eV2Transformer.transformSpell($0) }
            
            print("✅ V2 SPELLS: Fetched \(spells.count) spells")
            if let sourceKey = selectedSourceKey {
                print("   📌 Filter: \(sourceKey)")
            }
            
            return spells
        } catch {
            print("❌ API ERROR (Spells): \(error)")
            return []
        }
    }
    
    // MARK: - Sources
    
    func fetchAvailableSources() async throws -> [V2Source] {
        let url = URL(string: "https://api.open5e.com/v2/documents/")!
        
        print("🔗 SOURCES URL: \(url.absoluteString)")
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(V2SourcesResponse.self, from: data)
            
            print("✅ SOURCES: Fetched \(response.results.count) sources")
            
            return response.results
        } catch {
            print("❌ API ERROR (Sources): \(error)")
            return []
        }
    }
}
