import Foundation
import SwiftData
import SwiftUI

// MARK: - Enums
enum CardLayout: String, CaseIterable, Codable {
    case landscape35x5 = "3.5x5"
    case landscape4x6 = "4x6"
    
    var width: CGFloat {
        switch self {
        case .landscape35x5: return 480
        case .landscape4x6: return 576
        }
    }
    
    var height: CGFloat {
        switch self {
        case .landscape35x5: return 336
        case .landscape4x6: return 384
        }
    }
    
    var charCapacity: Int {
        switch self {
        case .landscape35x5: return 1350
        case .landscape4x6: return 1650
        }
    }
}

enum CardCategory: String, CaseIterable, Codable {
    case item = "Item"
    case spell = "Spell"
    case npc = "NPC"
    case location = "Location"
    case weapon = "Weapon"
    case armor = "Armor"
    case magicItem = "Magic Item"
}

// MARK: - Helper Structs
struct ItemStat: Identifiable, Codable, Hashable {
    var id = UUID()
    var label: String
    var value: String
}

struct ItemProperty: Identifiable, Codable, Hashable {
    var id = UUID()
    var label: String
    var value: String
}

// MARK: - Card Collection Model
@Model
class CardCollection: Identifiable {
    var id: UUID
    var name: String
    var icon: String // SF Symbol name
    var colorHex: String
    var createdDate: Date
    
    // Relationship to Cards
    @Relationship(deleteRule: .nullify, inverse: \Card.collection)
    var cards: [Card]? = []
    
    init(name: String, icon: String = "folder", colorHex: String = "0000FF") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.createdDate = Date()
    }
}

// MARK: - Card Model
@Model
class Card: Identifiable {
    var id: UUID
    var title: String
    var subtitle: String
    var category: CardCategory
    var itemDescription: String
    var source: String
    var createdDate: Date
    var tags: [String]
    
    // Collection Relationship
    var collection: CardCollection?
    
    var stats: [ItemStat]
    var properties: [ItemProperty]

    @Relationship(deleteRule: .cascade) var spellDetails: SpellDetails?
    @Relationship(deleteRule: .cascade) var weaponDetails: WeaponDetails?
    @Relationship(deleteRule: .cascade) var armorDetails: ArmorDetails?
    @Relationship(deleteRule: .cascade) var magicItemDetails: MagicItemDetails?
    @Relationship(deleteRule: .cascade) var npcDetails: NPCDetails?
    @Relationship(deleteRule: .cascade) var locationDetails: LocationDetails?

    init(title: String, subtitle: String, category: CardCategory, description: String, source: String, stats: [ItemStat] = [], properties: [ItemProperty] = [], tags: [String] = [], collection: CardCollection? = nil) {
        self.id = UUID()
        self.title = title
        self.subtitle = subtitle
        self.category = category
        self.itemDescription = description
        self.source = source
        self.stats = stats
        self.properties = properties
        self.tags = tags
        self.collection = collection
        self.createdDate = Date()
    }
}

// MARK: - Detail Models

@Model
class SpellDetails {
    var level: String
    var school: String
    var castingTime: String
    var range: String
    var components: String
    var duration: String
    var concentration: Bool
    var ritual: Bool
    var classes: String
    
    init(level: String, school: String, castingTime: String, range: String, components: String, duration: String, concentration: Bool, ritual: Bool, classes: String) {
        self.level = level
        self.school = school
        self.castingTime = castingTime
        self.range = range
        self.components = components
        self.duration = duration
        self.concentration = concentration
        self.ritual = ritual
        self.classes = classes
    }
}

@Model
class WeaponDetails {
    var damageDice: String
    var damageType: String
    var range: String?
    var mastery: String?
    var isSimple: Bool
    var properties: [String]
    
    init(damageDice: String, damageType: String, range: String? = nil, mastery: String? = nil, isSimple: Bool, properties: [String] = []) {
        self.damageDice = damageDice
        self.damageType = damageType
        self.range = range
        self.mastery = mastery
        self.isSimple = isSimple
        self.properties = properties
    }
}

@Model
class ArmorDetails {
    var ac: String
    var category: String
    var stealthDisadvantage: Bool
    var strengthReq: Int?
    
    init(ac: String, category: String, stealthDisadvantage: Bool, strengthReq: Int? = nil) {
        self.ac = ac
        self.category = category
        self.stealthDisadvantage = stealthDisadvantage
        self.strengthReq = strengthReq
    }
}

@Model
class MagicItemDetails {
    var type: String
    var rarity: String
    var requiresAttunement: Bool
    var attunementDetail: String?
    var magicBonus: String?
    
    init(type: String, rarity: String, requiresAttunement: Bool, attunementDetail: String? = nil, magicBonus: String? = nil) {
        self.type = type
        self.rarity = rarity
        self.requiresAttunement = requiresAttunement
        self.attunementDetail = attunementDetail
        self.magicBonus = magicBonus
    }
}

@Model
class NPCDetails {
    var ac: String
    var hp: String
    var cr: String
    var type: String
    
    var ancestry: String?
    var role: String?
    var archetype: String?
    var faction: String?
    
    var statblockName: String?
    var tier: Int?
    var signatureAction: String?
    var isCustomStatblock: Bool = false
    
    var persona: String?
    var drive: String?
    var utility: String?
    var stakes: String?
    var partyNotes: String?
    
    init(
        ac: String,
        hp: String,
        cr: String,
        type: String,
        ancestry: String? = nil,
        role: String? = nil,
        archetype: String? = nil,
        faction: String? = nil,
        statblockName: String? = nil,
        tier: Int? = nil,
        signatureAction: String? = nil,
        isCustomStatblock: Bool = false,
        persona: String? = nil,
        drive: String? = nil,
        utility: String? = nil,
        stakes: String? = nil,
        partyNotes: String? = nil
    ) {
        self.ac = ac
        self.hp = hp
        self.cr = cr
        self.type = type
        self.ancestry = ancestry
        self.role = role
        self.archetype = archetype
        self.faction = faction
        self.statblockName = statblockName
        self.tier = tier
        self.signatureAction = signatureAction
        self.isCustomStatblock = isCustomStatblock
        self.persona = persona
        self.drive = drive
        self.utility = utility
        self.stakes = stakes
        self.partyNotes = partyNotes
    }
    
    var cardSubtitle: String {
        var parts: [String] = []
        parts.append("Medium \(type)")
        if let role = role, !role.isEmpty {
            parts.append(role)
        }
        return parts.joined(separator: ", ")
    }
    
    var hasOptionalContent: Bool {
        return persona != nil || drive != nil || utility != nil || stakes != nil || partyNotes != nil
    }
}

extension NPCDetails {
    static func fromStatblock(_ statblock: StatblockReference, ancestry: String? = nil, role: String? = nil) -> NPCDetails {
        return NPCDetails(
            ac: String(statblock.ac),
            hp: String(statblock.hp),
            cr: statblock.cr,
            type: "Humanoid",
            ancestry: ancestry,
            role: role,
            archetype: statblock.archetype.rawValue,
            statblockName: statblock.name,
            tier: statblock.tier,
            signatureAction: statblock.signatureAction,
            isCustomStatblock: false
        )
    }
    
    static func custom(ac: String, hp: String, cr: String, type: String) -> NPCDetails {
        return NPCDetails(ac: ac, hp: hp, cr: cr, type: type, isCustomStatblock: true)
    }
}

@Model
class LocationDetails {
    var type: String
    var size: String
    var difficulty: Int
    
    var pointsOfInterest: String?
    var hooks: String?
    var hazards: String?
    var secrets: String?
    var notes: String?
    
    init(type: String, size: String, difficulty: Int, pointsOfInterest: String? = nil, hooks: String? = nil, hazards: String? = nil, secrets: String? = nil, notes: String? = nil) {
        self.type = type
        self.size = size
        self.difficulty = difficulty
        self.pointsOfInterest = pointsOfInterest
        self.hooks = hooks
        self.hazards = hazards
        self.secrets = secrets
        self.notes = notes
    }
}

// MARK: - Open5e Models (Used for Decoding)
struct Open5eItem: Codable, Identifiable {
    var id: String { key ?? name ?? UUID().uuidString }
    
    let key: String?
    let name: String?
    let desc: String?
    let type: String?
    let rarity: String?
    let requires_attunement: String?
    let document_title: String?
    let cost: String?
    
    let level: String?
    let school: String?
    let casting_time: String?
    let range: String?
    let components: String?
    let duration: String?
    let concentration: Bool?
    let ritual: Bool?
    let classes: String?
    
    var armor_category: String?
    var ac_string: String?
    var stealth_disadvantage: Bool?
    var strength_requirement: Int?
    var weapon_category: String?
    var damage_dice: String?
    var damage_type: String?
    
    enum CodingKeys: String, CodingKey {
        case key, name, desc, type, rarity, requires_attunement, cost
        case document_title = "document__title"
        case level, school, casting_time, range, components, duration
        case concentration, ritual, classes
        case armor_category, ac_string, stealth_disadvantage, strength_requirement
        case weapon_category, damage_dice, damage_type
        case armor, weapon
    }
    
    struct NestedArmor: Codable {
        let category: String?
        let ac_display: String?
        let grants_stealth_disadvantage: Bool?
        let strength_score_required: Int?
    }
    
    struct NestedWeapon: Codable {
        let category: String?
        let damage_dice: String?
        let damage_type: String?
    }
    
    struct RarityObj: Codable {
        let name: String
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        key = try container.decodeIfPresent(String.self, forKey: .key)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        desc = try container.decodeIfPresent(String.self, forKey: .desc)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        cost = try container.decodeIfPresent(String.self, forKey: .cost)
        
        if let rarityString = try? container.decodeIfPresent(String.self, forKey: .rarity) {
            rarity = rarityString
        } else if let rarityObj = try? container.decodeIfPresent(RarityObj.self, forKey: .rarity) {
            rarity = rarityObj.name
        } else {
            rarity = nil
        }
        
        if let boolAttune = try? container.decodeIfPresent(Bool.self, forKey: .requires_attunement) {
            requires_attunement = boolAttune ? "requires attunement" : nil
        } else {
            requires_attunement = try container.decodeIfPresent(String.self, forKey: .requires_attunement)
        }
        
        document_title = try container.decodeIfPresent(String.self, forKey: .document_title)
        level = try container.decodeIfPresent(String.self, forKey: .level)
        school = try container.decodeIfPresent(String.self, forKey: .school)
        casting_time = try container.decodeIfPresent(String.self, forKey: .casting_time)
        range = try container.decodeIfPresent(String.self, forKey: .range)
        components = try container.decodeIfPresent(String.self, forKey: .components)
        duration = try container.decodeIfPresent(String.self, forKey: .duration)
        classes = try container.decodeIfPresent(String.self, forKey: .classes)
        
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: .concentration) {
            concentration = boolValue
        } else if let stringValue = try? container.decodeIfPresent(String.self, forKey: .concentration) {
            concentration = stringValue.lowercased() == "yes" || stringValue == "1" || stringValue == "true"
        } else { concentration = nil }
        
        if let boolValue = try? container.decodeIfPresent(Bool.self, forKey: .ritual) { ritual = boolValue } else { ritual = nil }
        
        armor_category = try container.decodeIfPresent(String.self, forKey: .armor_category)
        ac_string = try container.decodeIfPresent(String.self, forKey: .ac_string)
        stealth_disadvantage = try container.decodeIfPresent(Bool.self, forKey: .stealth_disadvantage)
        strength_requirement = try container.decodeIfPresent(Int.self, forKey: .strength_requirement)
        
        weapon_category = try container.decodeIfPresent(String.self, forKey: .weapon_category)
        damage_dice = try container.decodeIfPresent(String.self, forKey: .damage_dice)
        damage_type = try container.decodeIfPresent(String.self, forKey: .damage_type)
        
        if let nestedArmor = try? container.decodeIfPresent(NestedArmor.self, forKey: .armor) {
            armor_category = nestedArmor.category
            ac_string = nestedArmor.ac_display
            stealth_disadvantage = nestedArmor.grants_stealth_disadvantage
            strength_requirement = nestedArmor.strength_score_required
        }
        
        if let nestedWeapon = try? container.decodeIfPresent(NestedWeapon.self, forKey: .weapon) {
            weapon_category = nestedWeapon.category
            damage_dice = nestedWeapon.damage_dice
            damage_type = nestedWeapon.damage_type
        }
    }
    
    // NEW: Manual Encode conformance
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(key, forKey: .key)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(desc, forKey: .desc)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(rarity, forKey: .rarity)
        try container.encodeIfPresent(requires_attunement, forKey: .requires_attunement)
        try container.encodeIfPresent(document_title, forKey: .document_title)
        try container.encodeIfPresent(cost, forKey: .cost)
        
        try container.encodeIfPresent(level, forKey: .level)
        try container.encodeIfPresent(school, forKey: .school)
        try container.encodeIfPresent(casting_time, forKey: .casting_time)
        try container.encodeIfPresent(range, forKey: .range)
        try container.encodeIfPresent(components, forKey: .components)
        try container.encodeIfPresent(duration, forKey: .duration)
        try container.encodeIfPresent(concentration, forKey: .concentration)
        try container.encodeIfPresent(ritual, forKey: .ritual)
        try container.encodeIfPresent(classes, forKey: .classes)
        
        try container.encodeIfPresent(armor_category, forKey: .armor_category)
        try container.encodeIfPresent(ac_string, forKey: .ac_string)
        try container.encodeIfPresent(stealth_disadvantage, forKey: .stealth_disadvantage)
        try container.encodeIfPresent(strength_requirement, forKey: .strength_requirement)
        try container.encodeIfPresent(weapon_category, forKey: .weapon_category)
        try container.encodeIfPresent(damage_dice, forKey: .damage_dice)
        try container.encodeIfPresent(damage_type, forKey: .damage_type)
    }
    
    // Manual Init
    init(name: String?, desc: String?, type: String?, rarity: String?, requires_attunement: String?, document_title: String?, level: String?, school: String?, casting_time: String?, range: String?, components: String?, duration: String?, concentration: Bool?, ritual: Bool?, classes: String?, armor_category: String? = nil, ac_string: String? = nil, stealth_disadvantage: Bool? = nil, strength_requirement: Int? = nil, weapon_category: String? = nil, damage_dice: String? = nil, damage_type: String? = nil, cost: String? = nil) {
        self.key = nil
        self.name = name
        self.desc = desc
        self.type = type
        self.rarity = rarity
        self.requires_attunement = requires_attunement
        self.document_title = document_title
        self.level = level
        self.school = school
        self.casting_time = casting_time
        self.range = range
        self.components = components
        self.duration = duration
        self.concentration = concentration
        self.ritual = ritual
        self.classes = classes
        self.armor_category = armor_category
        self.ac_string = ac_string
        self.stealth_disadvantage = stealth_disadvantage
        self.strength_requirement = strength_requirement
        self.weapon_category = weapon_category
        self.damage_dice = damage_dice
        self.damage_type = damage_type
        self.cost = cost
    }
}
