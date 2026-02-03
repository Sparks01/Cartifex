import Foundation

// MARK: - NPC Archetype & Statblock Reference System

struct StatblockReference: Identifiable, Codable {
    var id = UUID()
    let name: String
    let archetype: NPCArchetype
    let tier: Int
    let ac: Int
    let hp: Int
    let cr: String
    let signatureAction: String?
    
    var displayName: String {
        "\(name) (T\(tier))"
    }
}

enum NPCArchetype: String, CaseIterable, Codable {
    case muscle = "The Muscle"
    case social = "The Social"
    case criminal = "The Criminal"
    case devout = "The Devout"
    case arcanist = "The Arcanist"
    case woodsman = "The Woodsman"
    case thug = "The Thug"
    case leader = "The Leader"
    case performer = "The Performer"
    case occultist = "The Occultist"
    
    var description: String {
        switch self {
        case .muscle: return "Bodyguards, Mercenaries, Soldiers"
        case .social: return "Merchants, Nobles, Politicians"
        case .criminal: return "Thieves, Spies, Smugglers"
        case .devout: return "Clerics, Cultists, Priests"
        case .arcanist: return "Wizards, Sages, Scholars"
        case .woodsman: return "Rangers, Guides, Hunters"
        case .thug: return "Enforcers, Pirates, Bandits"
        case .leader: return "Captains, Knights, Commanders"
        case .performer: return "Bards, Heralds, Entertainers"
        case .occultist: return "Warlocks, Hermits, Dark Mages"
        }
    }
    
    var icon: String {
        switch self {
        case .muscle: return "shield.fill"
        case .social: return "person.2.fill"
        case .criminal: return "eye.slash.fill"
        case .devout: return "cross.fill"
        case .arcanist: return "book.fill"
        case .woodsman: return "leaf.fill"
        case .thug: return "fist.fill"
        case .leader: return "crown.fill"
        case .performer: return "music.note"
        case .occultist: return "moon.stars.fill"
        }
    }
}

// MARK: - Statblock Database

class NPCStatblockDatabase {
    static let shared = NPCStatblockDatabase()
    
    private init() {}
    
    // All available statblocks organized by archetype
    let statblocks: [NPCArchetype: [StatblockReference]] = [
        .muscle: [
            StatblockReference(name: "Guard", archetype: .muscle, tier: 1, ac: 16, hp: 11, cr: "1/8", signatureAction: nil),
            StatblockReference(name: "Veteran", archetype: .muscle, tier: 2, ac: 17, hp: 58, cr: "3", signatureAction: "Multiattack")
        ],
        
        .social: [
            StatblockReference(name: "Commoner", archetype: .social, tier: 1, ac: 10, hp: 4, cr: "0", signatureAction: nil),
            StatblockReference(name: "Noble", archetype: .social, tier: 2, ac: 15, hp: 9, cr: "1/8", signatureAction: "Influence")
        ],
        
        .criminal: [
            StatblockReference(name: "Spy", archetype: .criminal, tier: 1, ac: 12, hp: 27, cr: "1", signatureAction: "Sneak Attack"),
            StatblockReference(name: "Assassin", archetype: .criminal, tier: 2, ac: 15, hp: 78, cr: "8", signatureAction: "Sneak Attack (4d6)")
        ],
        
        .devout: [
            StatblockReference(name: "Acolyte", archetype: .devout, tier: 1, ac: 10, hp: 9, cr: "1/4", signatureAction: nil),
            StatblockReference(name: "Priest", archetype: .devout, tier: 2, ac: 13, hp: 27, cr: "2", signatureAction: "Healing Word")
        ],
        
        .arcanist: [
            StatblockReference(name: "Apprentice Wizard", archetype: .arcanist, tier: 1, ac: 10, hp: 9, cr: "1/4", signatureAction: nil),
            StatblockReference(name: "Mage", archetype: .arcanist, tier: 2, ac: 12, hp: 40, cr: "6", signatureAction: "Arcane Burst")
        ],
        
        .woodsman: [
            StatblockReference(name: "Scout", archetype: .woodsman, tier: 1, ac: 13, hp: 16, cr: "1/2", signatureAction: "Keen Senses"),
            StatblockReference(name: "Veteran Scout", archetype: .woodsman, tier: 2, ac: 17, hp: 58, cr: "3", signatureAction: "Multiattack")
        ],
        
        .thug: [
            StatblockReference(name: "Bandit", archetype: .thug, tier: 1, ac: 12, hp: 11, cr: "1/8", signatureAction: nil),
            StatblockReference(name: "Bandit Captain", archetype: .thug, tier: 2, ac: 15, hp: 65, cr: "2", signatureAction: "Multiattack")
        ],
        
        .leader: [
            StatblockReference(name: "Knight", archetype: .leader, tier: 1, ac: 18, hp: 52, cr: "3", signatureAction: "Leadership"),
            StatblockReference(name: "Warlord", archetype: .leader, tier: 2, ac: 18, hp: 229, cr: "12", signatureAction: "Leadership (1d4)")
        ],
        
        .performer: [
            StatblockReference(name: "Commoner", archetype: .performer, tier: 1, ac: 10, hp: 4, cr: "0", signatureAction: nil),
            StatblockReference(name: "Bard", archetype: .performer, tier: 2, ac: 15, hp: 44, cr: "2", signatureAction: "Countercharm")
        ],
        
        .occultist: [
            StatblockReference(name: "Cultist", archetype: .occultist, tier: 1, ac: 12, hp: 9, cr: "1/8", signatureAction: nil),
            StatblockReference(name: "Cult Fanatic", archetype: .occultist, tier: 2, ac: 13, hp: 33, cr: "2", signatureAction: "Dark Devotion")
        ]
    ]
    
    // Get all statblocks for an archetype
    func statblocks(for archetype: NPCArchetype) -> [StatblockReference] {
        return statblocks[archetype] ?? []
    }
    
    // Get a specific statblock
    func statblock(name: String, archetype: NPCArchetype) -> StatblockReference? {
        return statblocks[archetype]?.first { $0.name == name }
    }
    
    // Get all tier 1 statblocks
    var allTier1: [StatblockReference] {
        statblocks.values.flatMap { $0.filter { $0.tier == 1 } }
    }
    
    // Get all tier 2 statblocks
    var allTier2: [StatblockReference] {
        statblocks.values.flatMap { $0.filter { $0.tier == 2 } }
    }
    
    // Get all statblocks (for custom selection)
    var allStatblocks: [StatblockReference] {
        statblocks.values.flatMap { $0 }
    }
}

// MARK: - Common NPC Roles

enum NPCRole: String, CaseIterable, Codable {
    case shopkeeper = "Shopkeeper"
    case guardsman = "Guard"
    case scholar = "Scholar"
    case priest = "Priest"
    case noble = "Noble"
    case servant = "Servant"
    case criminal = "Criminal"
    case warrior = "Warrior"
    case mage = "Mage"
    case craftsperson = "Craftsperson"
    case farmer = "Farmer"
    case innkeeper = "Innkeeper"
    case merchant = "Merchant"
    case guide = "Guide"
    case entertainer = "Entertainer"
    case other = "Other"
}

// MARK: - Common Creature Types

enum CreatureType: String, CaseIterable, Codable {
    case humanoid = "Humanoid"
    case beast = "Beast"
    case dragon = "Dragon"
    case fey = "Fey"
    case fiend = "Fiend"
    case celestial = "Celestial"
    case undead = "Undead"
    case elemental = "Elemental"
    case construct = "Construct"
    case aberration = "Aberration"
    case monstrosity = "Monstrosity"
    case giant = "Giant"
    case ooze = "Ooze"
    case plant = "Plant"
}

// MARK: - Common Ancestries/Races

enum NPCAncestry: String, CaseIterable, Codable {
    case human = "Human"
    case elf = "Elf"
    case dwarf = "Dwarf"
    case halfling = "Halfling"
    case gnome = "Gnome"
    case halfElf = "Half-Elf"
    case halfOrc = "Half-Orc"
    case tiefling = "Tiefling"
    case dragonborn = "Dragonborn"
    case goblin = "Goblin"
    case orc = "Orc"
    case kobold = "Kobold"
    case other = "Other"
    
    var displayName: String {
        switch self {
        case .halfElf: return "Half-Elf"
        case .halfOrc: return "Half-Orc"
        default: return rawValue
        }
    }
}//
//  NPCStatblocks.swift
//  ItemCardCreatorapp
//
//  Created by Jose Munoz on 1/25/26.
//

import Foundation
