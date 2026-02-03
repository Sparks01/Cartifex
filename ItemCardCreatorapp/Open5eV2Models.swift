//
//  Open5eV2Models.swift
//  ItemCardCreatorApp
//
//  V2 API Response Models for 2024 SRD
//  Complete models for Spells, Magic Items, Armor, and Weapons
//

import Foundation

// MARK: - Shared Structs
struct V2WeaponProperty: Codable {
    let property: PropertyDetail
    let detail: String?
    struct PropertyDetail: Codable { let name: String; let type, desc: String? }
}

// MARK: - V2 API Responses
struct V2SourcesResponse: Codable {
    let count: Int; let next, previous: String?; let results: [V2Source]
}
struct V2Source: Codable, Identifiable, Hashable {
    let key, name, type: String; let display_name: String?
    var id: String { key }; var displayName: String { display_name ?? name }
}
struct V2SpellsResponse: Codable { let count: Int; let next, previous: String?; let results: [V2Spell] }
struct V2MagicItemsResponse: Codable { let count: Int; let next, previous: String?; let results: [V2MagicItem] }
struct V2ArmorResponse: Codable { let count: Int; let next, previous: String?; let results: [V2Armor] }
struct V2WeaponsResponse: Codable { let count: Int; let next, previous: String?; let results: [V2Weapon] }

// MARK: - V2 Spell Model
struct V2Spell: Codable, Identifiable {
    var id: String { key }
    let key, name, desc: String
    let level: Int
    let school: V2SpellSchool
    let casting_time, range_text, duration: String
    let concentration, ritual, verbal, somatic, material: Bool
    let material_specified: String?
    let classes: [V2SpellClass]?
    let document: V2Document
    
    enum CodingKeys: String, CodingKey {
        case key, name, desc, level, school, casting_time, range_text, duration
        case concentration, ritual, verbal, somatic, material, material_specified, classes, document
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        key = try container.decode(String.self, forKey: .key)
        name = try container.decode(String.self, forKey: .name)
        desc = try container.decode(String.self, forKey: .desc)
        level = try container.decode(Int.self, forKey: .level)
        school = try container.decode(V2SpellSchool.self, forKey: .school)
        casting_time = try container.decode(String.self, forKey: .casting_time)
        range_text = try container.decode(String.self, forKey: .range_text)
        duration = try container.decode(String.self, forKey: .duration)
        
        if let b = try? container.decode(Bool.self, forKey: .concentration) { concentration = b }
        else if let s = try? container.decode(String.self, forKey: .concentration) { concentration = s.lowercased() == "yes" }
        else { concentration = false }
        
        if let b = try? container.decode(Bool.self, forKey: .ritual) { ritual = b } else { ritual = false }
        verbal = (try? container.decode(Bool.self, forKey: .verbal)) ?? false
        somatic = (try? container.decode(Bool.self, forKey: .somatic)) ?? false
        material = (try? container.decode(Bool.self, forKey: .material)) ?? false
        
        material_specified = try container.decodeIfPresent(String.self, forKey: .material_specified)
        classes = try container.decodeIfPresent([V2SpellClass].self, forKey: .classes)
        document = try container.decode(V2Document.self, forKey: .document)
    }
    
    struct V2SpellSchool: Codable { let name, key, url: String }
    struct V2SpellClass: Codable { let name, key, url: String }
    struct V2Document: Codable { let key, name: String; let url: String? }
    
    var componentsString: String {
        var parts: [String] = []
        if verbal { parts.append("V") }
        if somatic { parts.append("S") }
        if material {
            if let m = material_specified, !m.isEmpty { parts.append("M (\(m))") }
            else { parts.append("M") }
        }
        return parts.joined(separator: ", ")
    }
    
    var levelString: String {
        switch level {
        case 0: return "Cantrip"; case 1: return "1st"; case 2: return "2nd"; case 3: return "3rd"
        default: return "\(level)th"
        }
    }
    var classesString: String? { classes?.map { $0.name }.joined(separator: ", ") }
}

// MARK: - V2 Magic Item Model
struct V2MagicItem: Codable, Identifiable {
    var id: String { key }
    let key, name, desc: String
    let category: V2Category?
    let rarity: V2Rarity?
    let requires_attunement: Bool
    let attunement_detail: String?
    let document: V2Document
    
    // Nested fields
    let weapon: V2WeaponDetail?
    let armor: V2ArmorDetail?
    
    struct V2Category: Codable { let key, name: String }
    struct V2Rarity: Codable { let key, name: String }
    struct V2Document: Codable { let key, name: String; let url: String? }
    
    struct V2WeaponDetail: Codable {
        let damage_dice: String?
        let damage_type: V2DamageType?
        let category: String?
        let properties: [V2WeaponProperty]?
        struct V2DamageType: Codable { let key, name: String? }
    }
    
    struct V2ArmorDetail: Codable {
        let name: String?
        let ac_display: String?
        let category: String?
        let grants_stealth_disadvantage: Bool?
        let strength_score_required: Int?
    }
    
    var typeString: String { category?.name ?? "Wondrous Item" }
    var attunementString: String {
        if !requires_attunement { return "" }
        if let detail = attunement_detail, !detail.isEmpty { return "requires attunement (\(detail))" }
        return "requires attunement"
    }
}

// MARK: - V2 Armor Model (Mundane)
struct V2Armor: Codable, Identifiable {
    var id: String { key }
    let key, name, category, ac_display: String
    let ac_base: Int
    let grants_stealth_disadvantage: Bool
    let strength_score_required: Int?
    let cost: String? // Added Cost
    let document: V2Document
    struct V2Document: Codable { let key, name: String; let url: String? }
    
    var descriptionString: String {
        var parts: [String] = []
        // Info is now in Grid, only special notes would go here
        return parts.joined(separator: "\n\n")
    }
}

// MARK: - V2 Weapon Model (Mundane)
struct V2Weapon: Codable, Identifiable {
    var id: String { key }
    let key, name, damage_dice: String
    let damage_type: V2DamageType
    let properties: [V2WeaponProperty]
    let range, long_range: Double
    let is_simple: Bool
    let cost: String? // Added Cost
    let document: V2Document
    struct V2DamageType: Codable { let name, key: String }
    struct V2Document: Codable { let key, name: String; let url: String? }
    
    var descriptionString: String {
        var parts: [String] = []
        for prop in properties {
            if let desc = prop.property.desc {
                parts.append("**\(prop.property.name):** \(desc)")
            }
        }
        return parts.joined(separator: "\n\n")
    }
}

// MARK: - Transformer

class Open5eV2Transformer {
    
    // Weapon Mastery Lookup
    private static let masteryLookup: [String: String] = [
        "club": "Slow", "dagger": "Nick", "greatclub": "Push", "handaxe": "Vex", "javelin": "Slow",
        "light hammer": "Nick", "mace": "Sap", "quarterstaff": "Topple", "sickle": "Nick", "spear": "Sap",
        "dart": "Vex", "light crossbow": "Slow", "shortbow": "Vex", "sling": "Slow",
        "battleaxe": "Topple", "flail": "Sap", "glaive": "Graze", "greataxe": "Cleave", "greatsword": "Graze",
        "halberd": "Cleave", "lance": "Topple", "longsword": "Sap", "maul": "Topple", "morningstar": "Sap",
        "pike": "Push", "rapier": "Vex", "scimitar": "Nick", "shortsword": "Vex", "trident": "Topple",
        "warhammer": "Push", "war pick": "Sap", "whip": "Slow", "blowgun": "Vex",
        "hand crossbow": "Vex", "heavy crossbow": "Push", "longbow": "Slow", "musket": "Slow", "pistol": "Vex"
    ]
    
    // Armor Stats Lookup
    private static let armorLookup: [String: (String, String, Bool, Int?)] = [
        "padded": ("11 + Dex", "Light", true, nil),
        "leather": ("11 + Dex", "Light", false, nil),
        "studded leather": ("12 + Dex", "Light", false, nil),
        "hide": ("12 + Dex (max 2)", "Medium", false, nil),
        "chain shirt": ("13 + Dex (max 2)", "Medium", false, nil),
        "scale mail": ("14 + Dex (max 2)", "Medium", true, nil),
        "breastplate": ("14 + Dex (max 2)", "Medium", false, nil),
        "half plate": ("15 + Dex (max 2)", "Medium", true, nil),
        "ring mail": ("14", "Heavy", true, nil),
        "chain mail": ("16", "Heavy", true, 13),
        "splint": ("17", "Heavy", true, 15),
        "plate": ("18", "Heavy", true, 15),
        "shield": ("+2", "Shield", false, nil)
    ]
    
    // MARK: - Legacy Transformers (Spells)
    static func transformSpell(_ v2Spell: V2Spell) -> Open5eItem {
        var durationString = v2Spell.duration
        if v2Spell.concentration { durationString = "Concentration, \(v2Spell.duration)" }
        return Open5eItem(name: v2Spell.name, desc: v2Spell.desc, type: nil, rarity: nil, requires_attunement: nil, document_title: v2Spell.document.name, level: v2Spell.levelString, school: v2Spell.school.name, casting_time: v2Spell.casting_time, range: v2Spell.range_text, components: v2Spell.componentsString, duration: durationString, concentration: v2Spell.concentration, ritual: v2Spell.ritual, classes: v2Spell.classesString)
    }
    
    static func transformMagicItem(_ v2Item: V2MagicItem) -> Open5eItem {
        return Open5eItem(name: v2Item.name, desc: v2Item.desc, type: v2Item.typeString, rarity: v2Item.rarity?.name, requires_attunement: v2Item.attunementString, document_title: v2Item.document.name, level: nil, school: nil, casting_time: nil, range: nil, components: nil, duration: nil, concentration: nil, ritual: nil, classes: nil)
    }
    
    // MARK: - Transform to Card
    
    static func transformMagicItemToCard(_ v2Item: V2MagicItem) -> Card {
        let magicBonusStr = extractMagicBonus(from: v2Item.name)
        let magicBonusInt = Int(magicBonusStr?.replacingOccurrences(of: "+", with: "") ?? "0") ?? 0
        let attunementClasses = parseAttunementClasses(from: v2Item.attunement_detail)
        let rarityName = v2Item.rarity?.name ?? "Unknown"
        let categoryKey = v2Item.category?.key.lowercased() ?? "wondrous-item"
        
        var finalCategory: CardCategory = .magicItem
        var stats: [ItemStat] = [ItemStat(label: "Rarity", value: rarityName)]
        
        // 1. Detect Category
        if v2Item.weapon != nil || categoryKey == "weapon" { finalCategory = .weapon }
        else if v2Item.armor != nil || categoryKey == "armor" || categoryKey == "shield" { finalCategory = .armor }
        
        // 2. PREPARE DETAILS
        var weaponDetails: WeaponDetails? = nil
        var armorDetails: ArmorDetails? = nil
        
        if finalCategory == .weapon {
            let dice = v2Item.weapon?.damage_dice ?? "1d8"
            let type = v2Item.weapon?.damage_type?.name ?? "Magic"
            let props = v2Item.weapon?.properties?.map { $0.property.name } ?? []
            let simple = v2Item.weapon?.category?.lowercased().contains("simple") ?? false
            
            var masteryName = v2Item.weapon?.properties?.first(where: { $0.property.type == "Mastery" })?.property.name
            if masteryName == nil {
                let lowerName = v2Item.name.lowercased()
                for (key, val) in masteryLookup { if lowerName.contains(key) { masteryName = val; break } }
            }
            weaponDetails = WeaponDetails(damageDice: dice, damageType: type, range: nil, mastery: masteryName, isSimple: simple, properties: props)
        }
        else if finalCategory == .armor {
            var ac = v2Item.armor?.ac_display
            var cat = v2Item.armor?.category
            var stealth = v2Item.armor?.grants_stealth_disadvantage
            var str = v2Item.armor?.strength_score_required
            
            // Lookup Fallback
            if ac == nil || cat == nil {
                let searchName = (v2Item.armor?.name ?? v2Item.name).lowercased()
                // Sort keys by length to find "Breastplate" before "Plate"
                let sortedKeys = armorLookup.keys.sorted { $0.count > $1.count }
                for key in sortedKeys {
                    if searchName.contains(key) {
                        let val = armorLookup[key]!
                        
                        if let baseACInt = Int(val.0) { ac = "\(baseACInt + magicBonusInt)" }
                        else if val.0.contains("+ Dex") {
                            if let basePrefix = Int(val.0.components(separatedBy: " ").first ?? "0") {
                                ac = val.0.replacingOccurrences(of: "\(basePrefix)", with: "\(basePrefix + magicBonusInt)")
                            } else { ac = val.0 }
                        } else { ac = val.0 }
                        cat = val.1; stealth = val.2; str = val.3
                        break
                    }
                }
            }
            armorDetails = ArmorDetails(ac: ac ?? "10", category: cat ?? "Medium", stealthDisadvantage: stealth ?? false, strengthReq: str)
        }
        
        // 3. GENERATE STATS GRID
        
        if finalCategory == .weapon, let w = weaponDetails {
            var dice = w.damageDice
            if let versProp = v2Item.weapon?.properties?.first(where: { $0.property.name == "Versatile" }), let detail = versProp.detail { dice += " (\(detail))" }
            stats.append(ItemStat(label: "Damage", value: dice))
            stats.append(ItemStat(label: "Type", value: w.damageType))
            stats.append(ItemStat(label: "Range", value: "Melee"))
            if v2Item.requires_attunement { stats.append(ItemStat(label: "Attunement", value: "Required")) }
            else { stats.append(ItemStat(label: "Rarity", value: rarityName)) }
            
        } else if finalCategory == .armor, let a = armorDetails {
            stats.append(ItemStat(label: "AC", value: cleanAC(a.ac)))
            
            if let str = a.strengthReq, str > 0 { stats.append(ItemStat(label: "Strength", value: "Str \(str)")) }
            else { stats.append(ItemStat(label: "Strength", value: "--")) }
            
            if a.stealthDisadvantage { stats.append(ItemStat(label: "Stealth", value: "Disadv")) }
            else { stats.append(ItemStat(label: "Stealth", value: "--")) }
            
            if v2Item.requires_attunement { stats.append(ItemStat(label: "Attunement", value: "Required")) }
            else { stats.append(ItemStat(label: "Rarity", value: rarityName)) }
        } else {
            stats.append(ItemStat(label: "Type", value: v2Item.typeString))
            stats.append(ItemStat(label: "Rarity", value: rarityName))
            if v2Item.requires_attunement { stats.append(ItemStat(label: "Attunement", value: "Required")) }
        }
        
        var properties: [ItemProperty] = []
        if v2Item.desc.contains("| 1d10 | Damage Type |") || v2Item.desc.contains("|1d10|Damage Type|") {
            properties.append(ItemProperty(label: "Resistance Type", value: "Roll 1d10"))
        }
        
        let card = Card(title: v2Item.name, subtitle: "\(v2Item.typeString), \(rarityName)", category: finalCategory, description: v2Item.desc, source: v2Item.document.name, stats: Array(stats.prefix(4)), properties: properties, tags: [rarityName, v2Item.typeString])
        
        card.magicItemDetails = MagicItemDetails(type: v2Item.typeString, rarity: rarityName, requiresAttunement: v2Item.requires_attunement, attunementDetail: attunementClasses, magicBonus: magicBonusStr)
        card.weaponDetails = weaponDetails
        card.armorDetails = armorDetails
        
        return card
    }
    
    static func transformWeaponToCard(_ v2Weapon: V2Weapon) -> Card {
        var masteryName = v2Weapon.properties.first { $0.property.type == "Mastery" }?.property.name
        if masteryName == nil {
            let lowerName = v2Weapon.name.lowercased()
            for (key, val) in masteryLookup { if lowerName.contains(key) { masteryName = val; break } }
        }
        let simpleProperties = v2Weapon.properties.filter { $0.property.type != "Mastery" }.map { $0.property.name }
        
        var stats: [ItemStat] = []
        var dice = v2Weapon.damage_dice
        if let versProp = v2Weapon.properties.first(where: { $0.property.name == "Versatile" }), let detail = versProp.detail { dice += " (\(detail))" }
        stats.append(ItemStat(label: "Damage", value: dice))
        stats.append(ItemStat(label: "Type", value: v2Weapon.damage_type.name))
        
        if v2Weapon.range > 0 {
            let r = "\(Int(v2Weapon.range))" + (v2Weapon.long_range > 0 ? "/\(Int(v2Weapon.long_range))" : "") + " ft"
            stats.append(ItemStat(label: "Range", value: r))
        } else {
            stats.append(ItemStat(label: "Range", value: "Melee"))
        }
        
        if let c = v2Weapon.cost, c != "0.00" { stats.append(ItemStat(label: "Cost", value: c)) }
        else { let typeLabel = v2Weapon.is_simple ? "Simple" : "Martial"; stats.append(ItemStat(label: "Type", value: typeLabel)) }
        
        let typeLabel = v2Weapon.is_simple ? "Simple" : "Martial"
        let card = Card(title: v2Weapon.name, subtitle: "\(typeLabel) Weapon", category: .weapon, description: v2Weapon.descriptionString, source: v2Weapon.document.name, stats: Array(stats.prefix(4)), properties: [], tags: [typeLabel, v2Weapon.damage_type.name])
        card.weaponDetails = WeaponDetails(damageDice: v2Weapon.damage_dice, damageType: v2Weapon.damage_type.name, range: nil, mastery: masteryName, isSimple: v2Weapon.is_simple, properties: simpleProperties)
        return card
    }
    
    static func transformArmorToCard(_ v2Armor: V2Armor) -> Card {
        var stats: [ItemStat] = []
        stats.append(ItemStat(label: "AC", value: cleanAC(v2Armor.ac_display)))
        
        if let str = v2Armor.strength_score_required { stats.append(ItemStat(label: "Strength", value: "Str \(str)")) }
        else { stats.append(ItemStat(label: "Strength", value: "--")) }
        
        if v2Armor.grants_stealth_disadvantage { stats.append(ItemStat(label: "Stealth", value: "Disadv")) }
        else { stats.append(ItemStat(label: "Stealth", value: "--")) }
        
        if let c = v2Armor.cost { stats.append(ItemStat(label: "Cost", value: c)) }
        else { stats.append(ItemStat(label: "Source", value: "5e")) }
        
        let card = Card(title: v2Armor.name, subtitle: "\(v2Armor.category.capitalized) Armor", category: .armor, description: v2Armor.descriptionString, source: v2Armor.document.name, stats: Array(stats.prefix(4)), properties: [], tags: [v2Armor.category.capitalized, "Armor"])
        card.armorDetails = ArmorDetails(ac: v2Armor.ac_display, category: v2Armor.category, stealthDisadvantage: v2Armor.grants_stealth_disadvantage, strengthReq: v2Armor.strength_score_required)
        return card
    }
    
    // MARK: - Helper Methods
    private static func extractMagicBonus(from name: String) -> String? {
        let patterns = ["\\+1", "\\+2", "\\+3"]; for pattern in patterns { if let range = name.range(of: pattern, options: .regularExpression) { return String(name[range]) } }; return nil
    }
    private static func parseAttunementClasses(from detail: String?) -> String? {
        guard let detail = detail else { return nil }
        let classes = ["Artificer", "Barbarian", "Bard", "Cleric", "Druid", "Fighter", "Monk", "Paladin", "Ranger", "Rogue", "Sorcerer", "Warlock", "Wizard"]
        var found: [String] = []
        for className in classes { if detail.localizedCaseInsensitiveContains(className) { found.append(className) } }
        return found.isEmpty ? nil : found.joined(separator: ", ")
    }
    
    private static func cleanAC(_ ac: String) -> String {
        var clean = ac.replacingOccurrences(of: "Dexterity modifier", with: "Dex")
        clean = clean.replacingOccurrences(of: " + Dex", with: "+Dex")
        clean = clean.replacingOccurrences(of: " modifier", with: "")
        if let val = Int(clean), val < 10 { return "+\(val)" }
        return clean
    }
}
