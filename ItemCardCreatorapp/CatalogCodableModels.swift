//
//  CatalogCodableModels.swift
//  ItemCardCreatorapp
//
//  Created by Jose Munoz on 1/24/26.
//

import Foundation

// MARK: - Codable Wrappers for Disk Persistence

struct CodableCard: Codable, Identifiable {
    var id: UUID
    var title: String
    var subtitle: String
    var category: String // CardCategory.rawValue
    var itemDescription: String
    var source: String
    var createdDate: Date
    var tags: [String]
    
    var stats: [CodableItemStat]
    var properties: [CodableItemProperty]
    
    var spellDetails: CodableSpellDetails?
    var weaponDetails: CodableWeaponDetails?
    var armorDetails: CodableArmorDetails?
    var magicItemDetails: CodableMagicItemDetails?
    var npcDetails: CodableNPCDetails?
    var locationDetails: CodableLocationDetails?
    
    // MARK: - Convert to Card
    func toCard() -> Card {
        let card = Card(
            title: title,
            subtitle: subtitle,
            category: CardCategory(rawValue: category) ?? .item,
            description: itemDescription,
            source: source,
            stats: stats.map { ItemStat(label: $0.label, value: $0.value) },
            properties: properties.map { ItemProperty(label: $0.label, value: $0.value) },
            tags: tags
        )
        
        card.id = id
        card.createdDate = createdDate
        
        if let spell = spellDetails {
            card.spellDetails = SpellDetails(
                level: spell.level,
                school: spell.school,
                castingTime: spell.castingTime,
                range: spell.range,
                components: spell.components,
                duration: spell.duration,
                concentration: spell.concentration,
                ritual: spell.ritual,
                classes: spell.classes
            )
        }
        
        if let weapon = weaponDetails {
            card.weaponDetails = WeaponDetails(
                damageDice: weapon.damageDice,
                damageType: weapon.damageType,
                range: weapon.range,
                mastery: weapon.mastery,
                isSimple: weapon.isSimple,
                properties: weapon.properties
            )
        }
        
        if let armor = armorDetails {
            card.armorDetails = ArmorDetails(
                ac: armor.ac,
                category: armor.category,
                stealthDisadvantage: armor.stealthDisadvantage,
                strengthReq: armor.strengthReq
            )
        }
        
        if let magic = magicItemDetails {
            card.magicItemDetails = MagicItemDetails(
                type: magic.type,
                rarity: magic.rarity,
                requiresAttunement: magic.requiresAttunement,
                attunementDetail: magic.attunementDetail,
                magicBonus: magic.magicBonus
            )
        }
        
        if let npc = npcDetails {
            card.npcDetails = NPCDetails(
                ac: npc.ac,
                hp: npc.hp,
                cr: npc.cr,
                type: npc.type,
                ancestry: npc.ancestry,
                role: npc.role,
                archetype: npc.archetype,
                faction: npc.faction,
                statblockName: npc.statblockName,
                tier: npc.tier,
                signatureAction: npc.signatureAction,
                isCustomStatblock: npc.isCustomStatblock,
                persona: npc.persona,
                drive: npc.drive,
                utility: npc.utility,
                stakes: npc.stakes,
                partyNotes: npc.partyNotes
            )
        }
        
        if let location = locationDetails {
            card.locationDetails = LocationDetails(
                type: location.type,
                size: location.size,
                difficulty: location.difficulty,
                pointsOfInterest: location.pointsOfInterest,
                hooks: location.hooks,
                hazards: location.hazards,
                secrets: location.secrets,
                notes: location.notes
            )
        }
        
        return card
    }
    
    // MARK: - Convert from Card
    static func from(_ card: Card) -> CodableCard {
        CodableCard(
            id: card.id,
            title: card.title,
            subtitle: card.subtitle,
            category: card.category.rawValue,
            itemDescription: card.itemDescription,
            source: card.source,
            createdDate: card.createdDate,
            tags: card.tags,
            stats: card.stats.map { CodableItemStat(label: $0.label, value: $0.value) },
            properties: card.properties.map { CodableItemProperty(label: $0.label, value: $0.value) },
            spellDetails: card.spellDetails.map { CodableSpellDetails.from($0) },
            weaponDetails: card.weaponDetails.map { CodableWeaponDetails.from($0) },
            armorDetails: card.armorDetails.map { CodableArmorDetails.from($0) },
            magicItemDetails: card.magicItemDetails.map { CodableMagicItemDetails.from($0) },
            npcDetails: card.npcDetails.map { CodableNPCDetails.from($0) },
            locationDetails: card.locationDetails.map { CodableLocationDetails.from($0) }
        )
    }
}

// MARK: - Supporting Codable Structs

struct CodableItemStat: Codable {
    var label: String
    var value: String
}

struct CodableItemProperty: Codable {
    var label: String
    var value: String
}

struct CodableSpellDetails: Codable {
    var level: String
    var school: String
    var castingTime: String
    var range: String
    var components: String
    var duration: String
    var concentration: Bool
    var ritual: Bool
    var classes: String
    
    static func from(_ details: SpellDetails) -> CodableSpellDetails {
        CodableSpellDetails(
            level: details.level,
            school: details.school,
            castingTime: details.castingTime,
            range: details.range,
            components: details.components,
            duration: details.duration,
            concentration: details.concentration,
            ritual: details.ritual,
            classes: details.classes
        )
    }
}

struct CodableWeaponDetails: Codable {
    var damageDice: String
    var damageType: String
    var range: String?
    var mastery: String?
    var isSimple: Bool
    var properties: [String]
    
    static func from(_ details: WeaponDetails) -> CodableWeaponDetails {
        CodableWeaponDetails(
            damageDice: details.damageDice,
            damageType: details.damageType,
            range: details.range,
            mastery: details.mastery,
            isSimple: details.isSimple,
            properties: details.properties
        )
    }
}

struct CodableArmorDetails: Codable {
    var ac: String
    var category: String
    var stealthDisadvantage: Bool
    var strengthReq: Int?
    
    static func from(_ details: ArmorDetails) -> CodableArmorDetails {
        CodableArmorDetails(
            ac: details.ac,
            category: details.category,
            stealthDisadvantage: details.stealthDisadvantage,
            strengthReq: details.strengthReq
        )
    }
}

struct CodableMagicItemDetails: Codable {
    var type: String
    var rarity: String
    var requiresAttunement: Bool
    var attunementDetail: String?
    var magicBonus: String?
    
    static func from(_ details: MagicItemDetails) -> CodableMagicItemDetails {
        CodableMagicItemDetails(
            type: details.type,
            rarity: details.rarity,
            requiresAttunement: details.requiresAttunement,
            attunementDetail: details.attunementDetail,
            magicBonus: details.magicBonus
        )
    }
}

// MARK: - Updated CodableNPCDetails
// This replaces the existing CodableNPCDetails in CatalogCodableModels.swift

struct CodableNPCDetails: Codable {
    // Core Stats
    var ac: String
    var hp: String
    var cr: String
    var type: String
    
    // Identity
    var ancestry: String?
    var role: String?
    var archetype: String?
    var faction: String?
    
    // Statblock Reference
    var statblockName: String?
    var tier: Int?
    var signatureAction: String?
    var isCustomStatblock: Bool
    
    // Freeform Fields (New System)
    var persona: String?
    var drive: String?
    var utility: String?
    var stakes: String?
    var partyNotes: String?
    
    static func from(_ details: NPCDetails) -> CodableNPCDetails {
        CodableNPCDetails(
            ac: details.ac,
            hp: details.hp,
            cr: details.cr,
            type: details.type,
            ancestry: details.ancestry,
            role: details.role,
            archetype: details.archetype,
            faction: details.faction,
            statblockName: details.statblockName,
            tier: details.tier,
            signatureAction: details.signatureAction,
            isCustomStatblock: details.isCustomStatblock,
            persona: details.persona,
            drive: details.drive,
            utility: details.utility,
            stakes: details.stakes,
            partyNotes: details.partyNotes
        )
    }
}

struct CodableLocationDetails: Codable {
    var type: String
    var size: String
    var difficulty: Int
    var pointsOfInterest: String?
    var hooks: String?
    var hazards: String?
    var secrets: String?
    var notes: String?
    
    static func from(_ details: LocationDetails) -> CodableLocationDetails {
        CodableLocationDetails(
            type: details.type,
            size: details.size,
            difficulty: details.difficulty,
            pointsOfInterest: details.pointsOfInterest,
            hooks: details.hooks,
            hazards: details.hazards,
            secrets: details.secrets,
            notes: details.notes
        )
    }
}
