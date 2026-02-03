//
//  CardCreationViewModel.swift
//  ItemCardCreatorapp
//
//  Created by Jose Munoz on 12/10/25.
//

import SwiftUI
import SwiftData

@Observable
class CardCreationViewModel {
    // MARK: - Global State
    var category: CardCategory = .item
    var title: String = ""
    var description: String = ""
    var source: String = "Homebrew"
    var showCatalog = false
    
    // MARK: - Editing
    var editingCard: Card? = nil
    var isEditing: Bool { editingCard != nil }
    
    // MARK: - Organization
    var selectedCollection: CardCollection? = nil
    
    // MARK: - Item/Magic Item Specifics
    var itemType: String = "Wondrous Item"
    var itemRarity: String = "Common"
    var requiresAttunement: Bool = false
    var attunementDetail: String = ""
    var magicBonus: String = ""
    var itemCost: String = ""
    
    // MARK: - Spell Specifics
    var spellLevel: String = "Cantrip"
    var spellSchool: String = "Evocation"
    var castingTime: String = "1 Action"
    var range: String = "60 feet"
    var components: String = "V, S"
    var duration: String = "Instantaneous"
    var concentration: Bool = false
    var ritual: Bool = false
    var classes: String = ""
    
    // MARK: - NPC Specifics
    var npcAc: String = "10"
    var npcHp: String = "10"
    var npcCr: String = "1/4"
    var npcSub: String = "Medium Humanoid"
    // MARK: - NPC Expanded Properties (ADD THESE)

    // Identity
    var npcAncestry: String = "Human"
    var npcRole: String = "Shopkeeper"
    var npcArchetype: NPCArchetype? = nil
    var npcFaction: String = ""

    // Statblock Reference
    var npcStatblockName: String? = nil
    var npcTier: Int = 1
    var npcSignatureAction: String = ""
    var npcUseCustomStats: Bool = false

    // MARK: - Freeform Fields (6 Categories)
    // Note: description field = CONCEPT (Visuals & Role)
    var npcPersona: String = ""     // PERSONA - Voice & Vibe
    var npcDrive: String = ""       // DRIVE - Goals & Motivation (REQUIRED)
    var npcUtility: String = ""     // UTILITY - Info & Assets
    var npcStakes: String = ""      // STAKES - Leverage & Limits
    var npcPartyNotes: String = ""  // NOTES - Session Tracking

    // Section Expansion State
    var npcBasicsExpanded: Bool = false
    var npcSocialExpanded: Bool = false
    var npcSecretsExpanded: Bool = false
    var npcCombatExpanded: Bool = false
    var npcTraitsExpanded: Bool = false
    var npcNotesExpanded: Bool = false
    
    // MARK: - Location Specifics
    var locType: String = "Landmark"
    var locSize: String = "Small"
    var locDifficulty: Int = 10  // DC 5-20, default 10
    
    // MARK: - Freeform Location Fields
    // Note: description field = ATMOSPHERE (Senses & Mood)
    var locPointsOfInterest: String = ""  // POINTS OF INTEREST - Key Locations
    var locHooks: String = ""             // HOOKS - Why Players Care
    var locHazards: String = ""           // HAZARDS - Dangers & Challenges
    var locSecrets: String = ""           // SECRETS - Hidden Elements
    var locNotes: String = ""             // NOTES - Session Tracking
    
    // MARK: - Weapon Specifics
    var damageDice: String = ""
    var damageType: String = ""
    var weaponProperties: String = ""
    var mastery: String = ""
    var isSimple: Bool = false
    var weaponRange: String = ""
    
    // MARK: - Armor Specifics
    var armorACValue: String = ""
    var armorCategoryType: String = "" // Light, Medium, Heavy
    var stealthDisadvantage: Bool = false
    var strengthReq: Int? = nil
    
    // MARK: - Constants
    let spellLevels = ["Cantrip", "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th", "9th"]
    let schools = ["Abjuration", "Conjuration", "Divination", "Enchantment", "Evocation", "Illusion", "Necromancy", "Transmutation"]
    let rarities = ["Common", "Uncommon", "Rare", "Very Rare", "Legendary", "Artifact"]
    
    // 2024 Weapon Mastery Lookup Table
    private let masteryLookup: [String: String] = [
        "club": "Slow", "dagger": "Nick", "greatclub": "Push", "handaxe": "Vex", "javelin": "Slow",
        "light hammer": "Nick", "mace": "Sap", "quarterstaff": "Topple", "sickle": "Nick", "spear": "Sap",
        "dart": "Vex", "light crossbow": "Slow", "shortbow": "Vex", "sling": "Slow",
        "battleaxe": "Topple", "flail": "Sap", "glaive": "Graze", "greataxe": "Cleave", "greatsword": "Graze",
        "halberd": "Cleave", "lance": "Topple", "longsword": "Sap", "maul": "Topple", "morningstar": "Sap",
        "pike": "Push", "rapier": "Vex", "scimitar": "Nick", "shortsword": "Vex", "trident": "Topple",
        "warhammer": "Push", "war pick": "Sap", "whip": "Slow", "blowgun": "Vex",
        "hand crossbow": "Vex", "heavy crossbow": "Push", "longbow": "Slow", "musket": "Slow", "pistol": "Vex"
    ]
    
    // MARK: - Validation
    var canAddCard: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var validationMessage: String? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Card name is required" }
        if description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Description is required" }
        return nil
    }
    
    // MARK: - Actions
    
    func addCard(to context: ModelContext) throws {
            guard canAddCard else {
                throw CardCreationError.invalidData(validationMessage ?? "Invalid card data")
            }
            
            let finalSubtitle = generateSubtitle()
            let finalStats = generateStats()
            let finalProperties = generateProperties()
            let finalTags = generateTags()

            // Format description based on category
            let finalDescription: String
            if category == .npc {
                finalDescription = formatNPCDescription()
            } else if category == .location {
                finalDescription = formatLocationDescription()
            } else {
                finalDescription = description
            }

            let newCard = Card(
                title: title,
                subtitle: finalSubtitle,
                category: category,
                description: finalDescription,
                source: source,
                stats: finalStats,
                properties: finalProperties,
                tags: finalTags,
                collection: selectedCollection // <--- Now works because Models.swift is updated
            )
            
            func createMagicDetails() -> MagicItemDetails? {
                if itemRarity != "Common" || requiresAttunement || !magicBonus.isEmpty {
                    return MagicItemDetails(type: itemType, rarity: itemRarity, requiresAttunement: requiresAttunement, attunementDetail: attunementDetail.isEmpty ? nil : attunementDetail, magicBonus: magicBonus.isEmpty ? nil : magicBonus)
                }
                return nil
            }
            
            switch category {
            case .spell:
                let details = SpellDetails(level: spellLevel, school: spellSchool, castingTime: castingTime, range: range, components: components, duration: duration, concentration: concentration, ritual: ritual, classes: classes)
                newCard.spellDetails = details
                
            case .item, .magicItem:
                let details = MagicItemDetails(type: itemType, rarity: itemRarity, requiresAttunement: requiresAttunement, attunementDetail: attunementDetail.isEmpty ? nil : attunementDetail, magicBonus: magicBonus.isEmpty ? nil : magicBonus)
                newCard.magicItemDetails = details
                // FIXED: Explicitly use CardCategory.magicItem
                if requiresAttunement || !magicBonus.isEmpty || itemRarity != "Common" { newCard.category = CardCategory.magicItem }
                
            case .npc:
                let details = NPCDetails(
                    ac: npcAc,
                    hp: npcHp,
                    cr: npcCr,
                    type: npcSub,
                    ancestry: npcAncestry.isEmpty ? nil : npcAncestry,
                    role: npcRole.isEmpty ? nil : npcRole,
                    archetype: npcArchetype?.rawValue,
                    faction: npcFaction.isEmpty ? nil : npcFaction,
                    statblockName: npcStatblockName,
                    tier: npcTier,
                    signatureAction: npcSignatureAction.isEmpty ? nil : npcSignatureAction,
                    isCustomStatblock: npcUseCustomStats,
                    persona: npcPersona.isEmpty ? nil : npcPersona,
                    drive: npcDrive.isEmpty ? nil : npcDrive,
                    utility: npcUtility.isEmpty ? nil : npcUtility,
                    stakes: npcStakes.isEmpty ? nil : npcStakes,
                    partyNotes: npcPartyNotes.isEmpty ? nil : npcPartyNotes
                )
                newCard.npcDetails = details
                
            case .location:
                let details = LocationDetails(
                    type: locType,
                    size: locSize,
                    difficulty: locDifficulty,
                    pointsOfInterest: locPointsOfInterest.isEmpty ? nil : locPointsOfInterest,
                    hooks: locHooks.isEmpty ? nil : locHooks,
                    hazards: locHazards.isEmpty ? nil : locHazards,
                    secrets: locSecrets.isEmpty ? nil : locSecrets,
                    notes: locNotes.isEmpty ? nil : locNotes
                )
                newCard.locationDetails = details
                
            case .weapon:
                var finalMastery = mastery
                if finalMastery.isEmpty {
                    let lowerTitle = title.lowercased()
                    for (key, val) in masteryLookup {
                        if lowerTitle.contains(key) { finalMastery = val; break }
                    }
                }
                
                let propArray = weaponProperties.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                
                let details = WeaponDetails(
                    damageDice: damageDice,
                    damageType: damageType,
                    range: weaponRange.isEmpty ? nil : weaponRange,
                    mastery: finalMastery.isEmpty ? nil : finalMastery,
                    isSimple: isSimple,
                    properties: propArray
                )
                newCard.weaponDetails = details
                newCard.magicItemDetails = createMagicDetails()
                
            case .armor:
                let details = ArmorDetails(ac: armorACValue, category: armorCategoryType, stealthDisadvantage: stealthDisadvantage, strengthReq: strengthReq)
                newCard.armorDetails = details
                newCard.magicItemDetails = createMagicDetails()
            }
            
            context.insert(newCard)
            resetForm()
        }
    
    // MARK: - Live Preview
    
    /// Creates a Card from the current form state without inserting into any ModelContext.
    /// Used by CardPreviewPanel for live rendering.
    func buildPreviewCard() -> Card? {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        let finalSubtitle = generateSubtitle()
        let finalStats = generateStats()
        let finalProperties = generateProperties()
        let finalTags = generateTags()
        
        let finalDescription: String
        if category == .npc {
            finalDescription = formatNPCDescription()
        } else if category == .location {
            finalDescription = formatLocationDescription()
        } else {
            finalDescription = description
        }
        
        var effectiveCategory = category
        
        let previewCard = Card(
            title: title,
            subtitle: finalSubtitle,
            category: effectiveCategory,
            description: finalDescription,
            source: source,
            stats: finalStats,
            properties: finalProperties,
            tags: finalTags
        )
        
        func createMagicDetails() -> MagicItemDetails? {
            if itemRarity != "Common" || requiresAttunement || !magicBonus.isEmpty {
                return MagicItemDetails(type: itemType, rarity: itemRarity, requiresAttunement: requiresAttunement, attunementDetail: attunementDetail.isEmpty ? nil : attunementDetail, magicBonus: magicBonus.isEmpty ? nil : magicBonus)
            }
            return nil
        }
        
        switch category {
        case .spell:
            previewCard.spellDetails = SpellDetails(level: spellLevel, school: spellSchool, castingTime: castingTime, range: range, components: components, duration: duration, concentration: concentration, ritual: ritual, classes: classes)
            
        case .item, .magicItem:
            previewCard.magicItemDetails = MagicItemDetails(type: itemType, rarity: itemRarity, requiresAttunement: requiresAttunement, attunementDetail: attunementDetail.isEmpty ? nil : attunementDetail, magicBonus: magicBonus.isEmpty ? nil : magicBonus)
            if requiresAttunement || !magicBonus.isEmpty || itemRarity != "Common" { previewCard.category = .magicItem }
            
        case .npc:
            previewCard.npcDetails = NPCDetails(
                ac: npcAc, hp: npcHp, cr: npcCr, type: npcSub,
                ancestry: npcAncestry.isEmpty ? nil : npcAncestry,
                role: npcRole.isEmpty ? nil : npcRole,
                archetype: npcArchetype?.rawValue,
                faction: npcFaction.isEmpty ? nil : npcFaction,
                statblockName: npcStatblockName,
                tier: npcTier,
                signatureAction: npcSignatureAction.isEmpty ? nil : npcSignatureAction,
                isCustomStatblock: npcUseCustomStats,
                persona: npcPersona.isEmpty ? nil : npcPersona,
                drive: npcDrive.isEmpty ? nil : npcDrive,
                utility: npcUtility.isEmpty ? nil : npcUtility,
                stakes: npcStakes.isEmpty ? nil : npcStakes,
                partyNotes: npcPartyNotes.isEmpty ? nil : npcPartyNotes
            )
            
        case .location:
            previewCard.locationDetails = LocationDetails(
                type: locType, size: locSize, difficulty: locDifficulty,
                pointsOfInterest: locPointsOfInterest.isEmpty ? nil : locPointsOfInterest,
                hooks: locHooks.isEmpty ? nil : locHooks,
                hazards: locHazards.isEmpty ? nil : locHazards,
                secrets: locSecrets.isEmpty ? nil : locSecrets,
                notes: locNotes.isEmpty ? nil : locNotes
            )
            
        case .weapon:
            var finalMastery = mastery
            if finalMastery.isEmpty {
                let lowerTitle = title.lowercased()
                for (key, val) in masteryLookup {
                    if lowerTitle.contains(key) { finalMastery = val; break }
                }
            }
            let propArray = weaponProperties.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            previewCard.weaponDetails = WeaponDetails(damageDice: damageDice, damageType: damageType, range: weaponRange.isEmpty ? nil : weaponRange, mastery: finalMastery.isEmpty ? nil : finalMastery, isSimple: isSimple, properties: propArray)
            previewCard.magicItemDetails = createMagicDetails()
            
        case .armor:
            previewCard.armorDetails = ArmorDetails(ac: armorACValue, category: armorCategoryType, stealthDisadvantage: stealthDisadvantage, strengthReq: strengthReq)
            previewCard.magicItemDetails = createMagicDetails()
        }
        
        return previewCard
    }
    
    // MARK: - Helper Generators
    
    // MARK: - Shared Helpers
    
    /// Creates MagicItemDetails from current form state. Used by addCard, updateExistingCard, and buildPreviewCard.
    private func createMagicDetails() -> MagicItemDetails? {
        if itemRarity != "Common" || requiresAttunement || !magicBonus.isEmpty {
            return MagicItemDetails(type: itemType, rarity: itemRarity, requiresAttunement: requiresAttunement, attunementDetail: attunementDetail.isEmpty ? nil : attunementDetail, magicBonus: magicBonus.isEmpty ? nil : magicBonus)
        }
        return nil
    }
    
    private func generateSubtitle() -> String {
        switch category {
        case .spell: return spellLevel == "Cantrip" ? "\(spellSchool) Cantrip" : "\(spellLevel)-level \(spellSchool)"
        case .item, .magicItem: return "\(itemType), \(itemRarity)"
        case .npc: return npcSub
        case .location: return "\(locSize) \(locType) • DC \(locDifficulty)"
        case .weapon:
            let rarityPrefix = (itemRarity != "Common") ? "\(itemRarity) " : ""
            return "\(rarityPrefix)\(isSimple ? "Simple" : "Martial") Weapon"
        case .armor:
            let rarityPrefix = (itemRarity != "Common") ? "\(itemRarity) " : ""
            return "\(rarityPrefix)\(armorCategoryType) Armor"
        }
    }
    
    private func generateStats() -> [ItemStat] {
        var stats: [ItemStat] = []
        
        func extractHealing() -> String? {
            let pattern = #/\d+d\d+(\s*\+\s*\d+)?/#
            if let match = description.firstMatch(of: pattern) { return String(match.0) }
            return nil
        }
        
        switch category {
        case .spell:
            stats.append(ItemStat(label: "Time", value: castingTime))
            stats.append(ItemStat(label: "Range", value: range))
            stats.append(ItemStat(label: "Comp", value: components))
            stats.append(ItemStat(label: "Dur", value: duration))
            
        case .item, .magicItem:
            stats.append(ItemStat(label: "Type", value: itemType))
            stats.append(ItemStat(label: "Rarity", value: itemRarity))
            if title.localizedCaseInsensitiveContains("Potion"), let heal = extractHealing() {
                stats.append(ItemStat(label: "Heals", value: heal))
            } else if requiresAttunement {
                stats.append(ItemStat(label: "Attunement", value: "Required"))
            } else {
                stats.append(ItemStat(label: "Magic", value: "Yes"))
            }
            if !itemCost.isEmpty && itemCost != "0.00" && itemCost != "0" {
                stats.append(ItemStat(label: "Cost", value: itemCost))
            } else {
                stats.append(ItemStat(label: "Source", value: "5e"))
            }
            
        case .npc:
            stats.append(ItemStat(label: "AC", value: npcAc))
            stats.append(ItemStat(label: "HP", value: npcHp))
            stats.append(ItemStat(label: "STATBLOCK", value: npcStatblockName ?? "Custom"))
            stats.append(ItemStat(label: "CR", value: npcCr))
            
        case .location:
            // No stats bar for locations - info is in pills (Type, Size, DC)
            // This gives ~35pt more space for content
            break
            
        case .weapon:
            // Box 1: Damage Dice (Numbers)
            var dmgDisplay = damageDice
            if weaponProperties.localizedCaseInsensitiveContains("versatile") {
                if let match = weaponProperties.firstMatch(of: #/\(\d+d\d+\)/#) {
                    dmgDisplay += " \(match.0)"
                } else if damageDice == "1d8" { dmgDisplay += " (1d10)" }
                else if damageDice == "1d6" { dmgDisplay += " (1d8)" }
            }
            stats.append(ItemStat(label: "Damage", value: dmgDisplay))
            
            // Box 2: Type (Full word "Slashing")
            stats.append(ItemStat(label: "Type", value: damageType))
            
            // Box 3: Range
            if !weaponRange.isEmpty {
                stats.append(ItemStat(label: "Range", value: weaponRange))
            } else {
                stats.append(ItemStat(label: "Range", value: "Melee"))
            }
            
            // Box 4: Cost / Magic
            if requiresAttunement {
                stats.append(ItemStat(label: "Attunement", value: "Required"))
            } else if !itemRarity.isEmpty && itemRarity != "Common" {
                stats.append(ItemStat(label: "Rarity", value: itemRarity))
            } else if !itemCost.isEmpty {
                stats.append(ItemStat(label: "Cost", value: itemCost))
            } else {
                let typeLabel = isSimple ? "Simple" : "Martial"
                stats.append(ItemStat(label: "Type", value: typeLabel))
            }
            
        case .armor:
                    // Helper to clean AC for manual entry too
                    func cleanAC(_ ac: String) -> String {
                        if let val = Int(ac), val < 10, armorCategoryType.lowercased().contains("shield") {
                            return "+\(val)"
                        }
                        return ac
                    }
                    
                    // Box 1: AC
                    stats.append(ItemStat(label: "AC", value: cleanAC(armorACValue)))
                    
                    // Box 2: Strength
                    if let str = strengthReq, str > 0 {
                        stats.append(ItemStat(label: "Strength", value: "Str \(str)"))
                    } else {
                        stats.append(ItemStat(label: "Strength", value: "--"))
                    }
                    
                    // Box 3: Stealth
                    if stealthDisadvantage {
                        stats.append(ItemStat(label: "Stealth", value: "Disadv"))
                    } else {
                        stats.append(ItemStat(label: "Stealth", value: "--"))
                    }
                    
                    // Box 4: Attunement / Cost
                    if requiresAttunement {
                        stats.append(ItemStat(label: "Attunement", value: "Required"))
                    } else if !itemCost.isEmpty && itemCost != "0.00" && itemCost != "0" {
                        stats.append(ItemStat(label: "Cost", value: itemCost))
                    } else {
                        stats.append(ItemStat(label: "Rarity", value: itemRarity))
                    }
        }
        
        return Array(stats.prefix(4))
    }
    
    // MARK: - NPC Helper Methods

    func loadNPCFromStatblock(_ statblock: StatblockReference) {
        npcStatblockName = statblock.name
        npcTier = statblock.tier
        npcArchetype = statblock.archetype
        npcAc = String(statblock.ac)
        npcHp = String(statblock.hp)
        npcCr = statblock.cr
        npcSignatureAction = statblock.signatureAction ?? ""
        npcUseCustomStats = false
    }

    func generateNPCSubtitle() -> String {
        var parts: [String] = []
        
        if !npcSub.isEmpty {
            parts.append(npcSub)
        } else {
            parts.append("Medium Humanoid")
        }
        
        if !npcRole.isEmpty && npcRole != "Shopkeeper" {
            parts.append(npcRole)
        }
        
        return parts.joined(separator: ", ")
    }
    
   
    
    private func generateProperties() -> [ItemProperty] { [] }
    
    private func generateTags() -> [String] {
        var tags: [String] = [category.rawValue]
        switch category {
        case .spell:
            tags.append(contentsOf: [spellSchool, spellLevel])
            if concentration { tags.append("Concentration") }
            if ritual { tags.append("Ritual") }
            let classList = classes.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            tags.append(contentsOf: classList)
        case .item, .magicItem:
            tags.append(contentsOf: [itemRarity, itemType])
            if requiresAttunement { tags.append("Attunement") }
        case .npc: tags.append(contentsOf: ["NPC", npcCr])
        case .location: tags.append(locType)
        case .weapon:
            tags.append(isSimple ? "Simple" : "Martial")
            tags.append(damageType)
            if !mastery.isEmpty { tags.append("Mastery") }
        case .armor: tags.append(armorCategoryType)
        }
        return tags.filter { !$0.isEmpty }
    }
    
    private func resetForm() {
        editingCard = nil
        clearAllFields()
    }
    
    func clearAllFields() {
        // Global
        title = ""
        description = ""
        source = "Homebrew"
        
        // Item/Magic Item
        itemType = "Wondrous Item"
        itemRarity = "Common"
        requiresAttunement = false
        attunementDetail = ""
        magicBonus = ""
        itemCost = ""
        
        // Spell
        spellLevel = "Cantrip"
        spellSchool = "Evocation"
        castingTime = "1 Action"
        range = "60 feet"
        components = "V, S"
        duration = "Instantaneous"
        concentration = false
        ritual = false
        classes = ""
        
        // NPC
        npcAc = "10"
        npcHp = "10"
        npcCr = "1/4"
        npcSub = "Medium Humanoid"
        npcAncestry = "Human"
        npcRole = "Shopkeeper"
        npcArchetype = nil
        npcFaction = ""
        npcStatblockName = nil
        npcTier = 1
        npcSignatureAction = ""
        npcUseCustomStats = false
        npcPersona = ""
        npcDrive = ""
        npcUtility = ""
        npcStakes = ""
        npcPartyNotes = ""
        
        // Reset expansion states (no longer used but keeping for compatibility)
        npcBasicsExpanded = false
        npcSocialExpanded = false
        npcSecretsExpanded = false
        npcCombatExpanded = false
        npcTraitsExpanded = false
        npcNotesExpanded = false
        
        // Location
        locType = "Landmark"
        locSize = "Small"
        locDifficulty = 10
        locPointsOfInterest = ""
        locHooks = ""
        locHazards = ""
        locSecrets = ""
        locNotes = ""
        
        // Weapon
        damageDice = ""
        damageType = ""
        weaponProperties = ""
        mastery = ""
        isSimple = false
        weaponRange = ""
        
        // Armor
        armorACValue = ""
        armorCategoryType = ""
        stealthDisadvantage = false
        strengthReq = nil
        
        // Reset collection
        selectedCollection = nil
        
        // Reset editing state
        editingCard = nil
    }
    
    // MARK: - Save (Create or Update)
    
    /// Unified save: creates a new card or updates the editing card.
    func saveCard(to context: ModelContext) throws {
        if let existingCard = editingCard {
            // Update existing card in place
            try updateExistingCard(existingCard, in: context)
        } else {
            // Create new card
            try addCard(to: context)
        }
    }
    
    /// Updates an existing card with current form values.
    private func updateExistingCard(_ card: Card, in context: ModelContext) throws {
        guard canAddCard else {
            throw CardCreationError.invalidData(validationMessage ?? "Invalid card data")
        }
        
        let finalSubtitle = generateSubtitle()
        let finalStats = generateStats()
        let finalProperties = generateProperties()
        let finalTags = generateTags()
        
        let finalDescription: String
        if category == .npc {
            finalDescription = formatNPCDescription()
        } else if category == .location {
            finalDescription = formatLocationDescription()
        } else {
            finalDescription = description
        }
        
        // Determine final category (promote to magicItem if applicable)
        var finalCategory = category
        if category == .item && (!itemRarity.isEmpty && itemRarity != "Common" || requiresAttunement || !magicBonus.isEmpty) {
            finalCategory = .magicItem
        }
        
        // Update basic fields
        card.title = title
        card.subtitle = finalSubtitle
        card.category = finalCategory
        card.itemDescription = finalDescription
        card.source = source
        card.stats = finalStats
        card.properties = finalProperties
        card.tags = finalTags
        card.collection = selectedCollection
        
        // Clear old detail objects
        card.spellDetails = nil
        card.magicItemDetails = nil
        card.npcDetails = nil
        card.locationDetails = nil
        card.weaponDetails = nil
        card.armorDetails = nil
        
        // Re-create category-specific details (same logic as addCard)
        switch category {
        case .item, .magicItem:
            card.magicItemDetails = createMagicDetails()
            
        case .spell:
            card.spellDetails = SpellDetails(
                level: spellLevel, school: spellSchool,
                castingTime: castingTime, range: range,
                components: components, duration: duration,
                concentration: concentration, ritual: ritual, classes: classes
            )
            
        case .npc:
            card.npcDetails = NPCDetails(
                ac: npcAc, hp: npcHp, cr: npcCr, type: npcSub,
                ancestry: npcAncestry.isEmpty ? nil : npcAncestry,
                role: npcRole.isEmpty ? nil : npcRole,
                archetype: npcArchetype?.rawValue,
                faction: npcFaction.isEmpty ? nil : npcFaction,
                statblockName: npcStatblockName,
                tier: npcTier,
                signatureAction: npcSignatureAction.isEmpty ? nil : npcSignatureAction,
                isCustomStatblock: npcUseCustomStats,
                persona: npcPersona.isEmpty ? nil : npcPersona,
                drive: npcDrive.isEmpty ? nil : npcDrive,
                utility: npcUtility.isEmpty ? nil : npcUtility,
                stakes: npcStakes.isEmpty ? nil : npcStakes,
                partyNotes: npcPartyNotes.isEmpty ? nil : npcPartyNotes
            )
            
        case .location:
            card.locationDetails = LocationDetails(
                type: locType, size: locSize, difficulty: locDifficulty,
                pointsOfInterest: locPointsOfInterest.isEmpty ? nil : locPointsOfInterest,
                hooks: locHooks.isEmpty ? nil : locHooks,
                hazards: locHazards.isEmpty ? nil : locHazards,
                secrets: locSecrets.isEmpty ? nil : locSecrets,
                notes: locNotes.isEmpty ? nil : locNotes
            )
            
        case .weapon:
            var finalMastery = mastery
            if finalMastery.isEmpty {
                let lowerTitle = title.lowercased()
                for (key, val) in masteryLookup {
                    if lowerTitle.contains(key) { finalMastery = val; break }
                }
            }
            let propArray = weaponProperties.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            card.weaponDetails = WeaponDetails(
                damageDice: damageDice, damageType: damageType,
                range: weaponRange.isEmpty ? nil : weaponRange,
                mastery: finalMastery.isEmpty ? nil : finalMastery,
                isSimple: isSimple, properties: propArray
            )
            card.magicItemDetails = createMagicDetails()
            
        case .armor:
            card.armorDetails = ArmorDetails(ac: armorACValue, category: armorCategoryType, stealthDisadvantage: stealthDisadvantage, strengthReq: strengthReq)
            card.magicItemDetails = createMagicDetails()
        }
        
        resetForm()
    }
    
    // MARK: - Cancel Editing
    
    func cancelEditing() {
        resetForm()
    }
    
    // MARK: - Edit Existing Card
    
    /// Populates all form fields from an existing Card for editing.
    func loadFromCard(_ card: Card) {
        clearAllFields()
        editingCard = card
        
        // Basic fields
        title = card.title
        source = card.source
        // Map .magicItem back to .item for the form — save logic auto-promotes based on rarity/attunement
        category = (card.category == .magicItem) ? .item : card.category
        selectedCollection = card.collection
        
        // Category-specific details
        switch card.category {
        case .spell:
            if let s = card.spellDetails {
                spellLevel = s.level
                spellSchool = s.school
                castingTime = s.castingTime
                range = s.range
                components = s.components
                duration = s.duration
                concentration = s.concentration
                ritual = s.ritual
                classes = s.classes
            }
            description = card.itemDescription
            
        case .item, .magicItem:
            if let m = card.magicItemDetails {
                itemType = m.type
                itemRarity = sanitizeRarity(m.rarity)
                requiresAttunement = m.requiresAttunement
                attunementDetail = m.attunementDetail ?? ""
                magicBonus = m.magicBonus ?? ""
            }
            description = card.itemDescription
            
        case .npc:
            if let n = card.npcDetails {
                npcAc = n.ac
                npcHp = n.hp
                npcCr = n.cr
                npcSub = n.type
                npcAncestry = n.ancestry ?? "Human"
                npcRole = n.role ?? "Shopkeeper"
                npcFaction = n.faction ?? ""
                if let archStr = n.archetype {
                    npcArchetype = NPCArchetype(rawValue: archStr)
                }
                npcStatblockName = n.statblockName
                npcTier = n.tier ?? 1
                npcSignatureAction = n.signatureAction ?? ""
                npcUseCustomStats = n.isCustomStatblock
                npcPersona = n.persona ?? ""
                npcDrive = n.drive ?? ""
                npcUtility = n.utility ?? ""
                npcStakes = n.stakes ?? ""
                npcPartyNotes = n.partyNotes ?? ""
            }
            // Parse formatted description back into freeform fields
            if let desc = card.itemDescription as String? {
                description = extractFormattedSection(from: desc, header: "CONCEPT") ?? ""
                if npcPersona.isEmpty { npcPersona = extractFormattedSection(from: desc, header: "PERSONA") ?? "" }
                if npcDrive.isEmpty { npcDrive = extractFormattedSection(from: desc, header: "DRIVE") ?? "" }
                if npcUtility.isEmpty { npcUtility = extractFormattedSection(from: desc, header: "UTILITY") ?? "" }
                if npcStakes.isEmpty { npcStakes = extractFormattedSection(from: desc, header: "STAKES") ?? "" }
                if npcPartyNotes.isEmpty { npcPartyNotes = extractFormattedSection(from: desc, header: "NOTES") ?? "" }
            }
            
        case .location:
            if let l = card.locationDetails {
                locType = l.type
                locSize = l.size
                locDifficulty = l.difficulty
                locPointsOfInterest = l.pointsOfInterest ?? ""
                locHooks = l.hooks ?? ""
                locHazards = l.hazards ?? ""
                locSecrets = l.secrets ?? ""
                locNotes = l.notes ?? ""
            }
            // Parse formatted description back into freeform fields
            if let desc = card.itemDescription as String? {
                description = extractFormattedSection(from: desc, header: "ATMOSPHERE") ?? ""
                if locPointsOfInterest.isEmpty { locPointsOfInterest = extractFormattedSection(from: desc, header: "POINTS OF INTEREST") ?? "" }
                if locHooks.isEmpty { locHooks = extractFormattedSection(from: desc, header: "HOOKS") ?? "" }
                if locHazards.isEmpty { locHazards = extractFormattedSection(from: desc, header: "HAZARDS") ?? "" }
                if locSecrets.isEmpty { locSecrets = extractFormattedSection(from: desc, header: "SECRETS") ?? "" }
                if locNotes.isEmpty { locNotes = extractFormattedSection(from: desc, header: "NOTES") ?? "" }
            }
            
        case .weapon:
            if let w = card.weaponDetails {
                damageDice = w.damageDice
                damageType = w.damageType
                weaponRange = w.range ?? ""
                mastery = w.mastery ?? ""
                isSimple = w.isSimple
                weaponProperties = w.properties.joined(separator: ", ")
            }
            if let m = card.magicItemDetails {
                itemRarity = sanitizeRarity(m.rarity)
                requiresAttunement = m.requiresAttunement
                attunementDetail = m.attunementDetail ?? ""
                magicBonus = m.magicBonus ?? ""
            }
            description = card.itemDescription
            
        case .armor:
            if let a = card.armorDetails {
                armorACValue = a.ac
                armorCategoryType = a.category
                stealthDisadvantage = a.stealthDisadvantage
                strengthReq = a.strengthReq
            }
            if let m = card.magicItemDetails {
                itemRarity = sanitizeRarity(m.rarity)
                requiresAttunement = m.requiresAttunement
                attunementDetail = m.attunementDetail ?? ""
                magicBonus = m.magicBonus ?? ""
            }
            description = card.itemDescription
        }
    }
    
    /// Maps stored rarity values that don't match picker options back to valid ones.
    /// Handles "Unknown", empty strings, and variant capitalizations from Open5e data.
    private func sanitizeRarity(_ rarity: String) -> String {
        let valid = Set(rarities) // ["Common", "Uncommon", "Rare", "Very Rare", "Legendary", "Artifact"]
        if valid.contains(rarity) { return rarity }
        
        // Try case-insensitive match
        let lower = rarity.lowercased()
        if let match = rarities.first(where: { $0.lowercased() == lower }) { return match }
        
        // "varies", "unknown", empty → default to Common
        return "Common"
    }
    
    /// Extracts a section's content from a formatted NPC/Location description.
    private func extractFormattedSection(from text: String, header: String) -> String? {
        let pattern = "【\(header)】"
        guard let headerRange = text.range(of: pattern) else { return nil }
        let afterHeader = text[headerRange.upperBound...]
        
        // Find the next section header or end of string
        if let nextHeader = afterHeader.range(of: "【") {
            let content = afterHeader[..<nextHeader.lowerBound]
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            return afterHeader.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    // MARK: - Load from API
    
    func loadFromOpen5eItem(_ item: Open5eItem) {
        self.title = item.name ?? "Untitled"
        let rawDesc = item.desc ?? ""
                self.description = rawDesc
                    .replacingOccurrences(of: "\\n", with: "\n") // Fix escaped newlines
                    .replacingOccurrences(of: "\\r", with: "")
                    .replacingOccurrences(of: "â€™", with: "'")   // Common encoding error fix
                    .replacingOccurrences(of: "â€", with: "-")    // Common encoding error fix
                
                self.source = item.document_title ?? "Open5e"
        
        self.mastery = ""
        self.weaponProperties = ""
        self.damageDice = ""
        self.magicBonus = ""
        self.weaponRange = ""
        self.itemCost = item.cost ?? ""
        
        if let level = item.level, let school = item.school {
            self.category = .spell
            self.spellLevel = level
            self.spellSchool = school
            self.castingTime = item.casting_time ?? "1 Action"
            self.range = item.range ?? "Touch"
            self.components = item.components ?? "V, S"
            self.duration = item.duration ?? "Instantaneous"
            self.concentration = item.concentration ?? false
            self.ritual = item.ritual ?? false
            self.classes = item.classes ?? ""
            
        } else if let type = item.type, let rarity = item.rarity {
            self.category = .magicItem
            self.itemType = type
            self.itemRarity = rarity
            
            if let attune = item.requires_attunement {
                if attune.lowercased() == "requires attunement" {
                    self.requiresAttunement = true
                    self.attunementDetail = ""
                } else if attune.lowercased().contains("attunement") {
                    self.requiresAttunement = true
                    self.attunementDetail = attune
                } else {
                    self.requiresAttunement = false
                }
            }
            if let name = item.name {
                if name.contains("+1") { self.magicBonus = "+1" }
                else if name.contains("+2") { self.magicBonus = "+2" }
                else if name.contains("+3") { self.magicBonus = "+3" }
            }
            
        } else if let armorCat = item.armor_category {
            self.category = .armor
            self.armorCategoryType = armorCat
            self.armorACValue = item.ac_string ?? "10"
            self.stealthDisadvantage = item.stealth_disadvantage ?? false
            self.strengthReq = item.strength_requirement
            
        } else if let weaponCat = item.weapon_category {
            self.category = .weapon
            self.isSimple = weaponCat.lowercased().contains("simple")
            self.damageDice = item.damage_dice ?? "1d4"
            self.damageType = item.damage_type ?? "bludgeoning"
            self.weaponRange = item.range ?? ""
            
        } else {
            self.category = .item
            self.itemType = item.type ?? "Wondrous Item"
            self.itemRarity = item.rarity ?? "Common"
        }
    }
}

// MARK: - Debug / Sample Data Extension
extension CardCreationViewModel {
    func populateSampleNPC(variant: Int) {
        // 1. Clear existing
        clearAllFields()
        
        // 2. Set generic NPC defaults
        category = .npc
        npcUseCustomStats = true // Allow editing text fields
        
        switch variant {
        case 1: // Father Lucian - Quest Giver
            title = "Father Lucian"
            description = "Older man. White hair. Kind brown eyes. Stronger than he looks."
            npcSub = "Medium Humanoid (Human)"
            npcAncestry = "Human"
            npcRole = "Priest"
            npcArchetype = .devout
            npcFaction = "The Church"
            npcTier = 1
            
            npcAc = "10"
            npcHp = "9"
            npcCr = "1/8"
            
            npcPersona = "Speaks in a hushed whisper, constantly wringing his hands when discussing the 'Old Gods'. Nervous but earnest."
            npcDrive = "Wants to restore the desecrated shrine on the hill before the winter festival. Fears the village will lose faith if he fails."
            npcUtility = "He is an expert in herbal medicine and alchemy. Can offer healing potions (2), safe shelter in the vestry."
            npcStakes = "Won't help if the party openly displays necromantic symbols. Can be convinced with displays of genuine piety."
            npcPartyNotes = "He is a devout cleric, and is known for his piety and kindness. He is also a skilled healer, and can be found tending to the wounded in the village square."
            
        case 2: // Krag - Muscle
            title = "Krag 'Iron-Tooth'"
            description = "Massive Half-Orc with a prosthetic iron tooth. Scars crisscross his knuckles."
            npcSub = "Medium Humanoid (Half-Orc)"
            npcAncestry = "Half-Orc"
            npcRole = "Enforcer"
            npcArchetype = .thug
            npcFaction = "The Oarmongers"
            npcTier = 2
            
            npcAc = "16"
            npcHp = "65"
            npcCr = "3"
            
            npcPersona = "Gruff, speaks in short sentences. Hammers fist into palm to intimidate. Surprisingly polite to children."
            npcDrive = "Wants to be feared enough that people pay without resistance. Deep down, wants respect, not just fear."
            npcUtility = "Knows gang hideouts, patrol routes, and which shopkeepers cooperate. Can arrange meetings with crime bosses."
            npcStakes = "Won't help if you insult his strength or the gang. Bribe with gold or beat him in single combat to earn respect."
            npcPartyNotes = ""
            
        case 3: // Lady Vanya - Schemer
            title = "Lady Vanya"
            description = "Tall. Long lavender hair. Elegant and sophisticated."
            npcSub = "Medium Humanoid (Elf)"
            npcAncestry = "Elf"
            npcRole = "Noble"
            npcArchetype = .social
            npcFaction = "House Vanya"
            npcTier = 2
            
            npcAc = "12"
            npcHp = "24"
            npcCr = "1/2"
            
            npcPersona = "Impeccably dressed in silk and velvet. Always wears gloves. Smiles often but it never reaches her eyes. Speaks in calculated phrases."
            npcDrive = "Wants to secure the trade contract for the western mines to expand her family's influence. Hiding her pact with a Fiend."
            npcUtility = "Knows the Mayor is being blackmailed by the Thieves Guild. Has dirt on most nobles in the city. Can open doors to high society."
            npcStakes = "Won't help if you threaten her reputation. Leverage her secret pact if discovered. She values discretion above all."
            npcPartyNotes = "Met at the ball. Player Rogue tried to pickpocket her and failed."
            
        default:
            break
        }
    }
    
    func populateSampleLocation(variant: Int) {
        // 1. Clear existing
        clearAllFields()
        
        // 2. Set generic Location defaults
        category = .location
        
        switch variant {
        case 1: // The Weeping Shrine - Dungeon/Ruins
            title = "The Weeping Shrine"
            description = "Crumbling stone walls draped in moss. The air is damp and cold, smelling of mildew and ancient incense. Water drips steadily from cracks in the vaulted ceiling, echoing through empty halls. Faded murals of forgotten gods line the walls."
            locType = "Dungeon"
            locSize = "Medium"
            locDifficulty = 15
            
            locPointsOfInterest = "Central prayer hall with collapsed ceiling. Ancient stone altar with mysterious runes (DC 15 Religion to decipher). East wing completely collapsed. Three alcoves with weathered statues. Underground crypt accessible via hidden stairs behind altar."
            locHooks = "Villagers claim a holy artifact—the Chalice of Dawn—is hidden within. Strange glowing lights seen at night through the broken windows. Local priest offers 200gp to retrieve sacred texts from the shrine. Cult of the Old Gods rumored to perform rituals here monthly."
            locHazards = "Unstable floors in east wing (DC 14 DEX save or fall 10ft, taking 3d6 damage). Poisonous spores in the crypt (DC 13 CON save or poisoned for 1 hour). 3 Shadows lurking in the dark corners. Trapped entrance to crypt (DC 16 Investigation to find, DC 15 Thieves' Tools to disarm)."
            locSecrets = "False bottom in altar reveals hidden chamber containing the Chalice of Dawn (worth 800gp, grants advantage on saving throws vs fear). Ancient journal hidden in crypt explains the shrine's true purpose: sealing an evil entity beneath the foundation. Touching all three statues in correct order opens passage to treasure vault (500gp, Potion of Greater Healing x2)."
            locNotes = ""
            
        case 2: // The Brass Mug Tavern - Social Hub
            title = "The Brass Mug Tavern"
            description = "Warm firelight flickers across rough-hewn wooden beams. The smell of roasted meat and spilled ale fills the air. A bard plays lively music in the corner while patrons laugh and argue over dice games. The brass mug hanging above the bar is polished to a shine."
            locType = "Social Space"
            locSize = "Small"
            locDifficulty = 10
            
            locPointsOfInterest = "Bar run by Gretta Ironfoot (dwarf, friendly, knows everyone's business). Private rooms upstairs (5sp/night). Bulletin board with job postings and local rumors. Basement storage where Gretta runs an unofficial pawn shop. Corner table where the Gray Cloaks (local mercenary group) always sit."
            locHooks = "Gretta offers work: investigate strange disappearances near the docks (pays 50gp). Mysterious hooded figure watching the party from the shadows. Job posting seeking escorts for merchant caravan (100gp each). Drunk patron claims to have seen a dragon's lair in the nearby mountains."
            locHazards = "Bar fights break out nightly around 10pm (DC 12 DEX to avoid getting involved). Pickpockets working the evening crowd (DC 14 Perception to notice, DC 16 Sleight of Hand to catch). Gray Cloaks take offense easily—insulting them starts combat with 4 Veterans. City watch raids the basement pawn shop once per week."
            locSecrets = "Gretta's pawn shop sells items with 'no questions asked'—including a stolen noble's signet ring (DC 15 Investigation to recognize). Secret door behind wine barrels leads to smuggler's tunnel connecting to the docks. Bard is actually a spy for the Thieves' Guild, gathering information. Bulletin board has coded messages for guild members (DC 18 Investigation to decode)."
            locNotes = ""
            
        case 3: // Thornwood Forest - Wilderness/Traversal
            title = "Thornwood Forest"
            description = "Dense canopy blocks most sunlight, casting everything in green-tinted shadow. Thick underbrush tears at clothing and exposed skin. The forest floor is spongy with decaying leaves. Bird calls echo strangely, and you occasionally hear something large moving through the trees ahead."
            locType = "Wilderness"
            locSize = "Vast"
            locDifficulty = 13
            
            locPointsOfInterest = "Ancient standing stones in a clearing (magical in nature). Stream running north to south, only safe water source. Massive hollow tree that could shelter 6 people. Abandoned woodcutter's cabin, half-reclaimed by vines. Game trail leading deeper into the forest (or toward the exit)."
            locHooks = "Shortcut to the capital saves 2 days travel. Rare herbs grow here worth 100gp to alchemists (DC 15 Nature to identify and harvest). Bandit camp somewhere in the depths. Elven ranger offers to guide party through for 25gp. Local legend speaks of a hidden fey grove with a magical fountain."
            locHazards = "Easy to get lost—navigation requires DC 13 Survival checks every 4 hours. Dense thorns require cutting through (1 hour per mile, DC 12 CON save or take 1 level exhaustion). 2d4 Bandits patrol the game trails. Owlbear lair near the standing stones. Quicksand patches near the stream (DC 14 Perception to spot, DC 15 STR to escape)."
            locSecrets = "Standing stones are a portal to the Feywild (only opens during full moon). Hidden cache buried near the hollow tree contains 300gp and a map to the bandit camp. Woodcutter's cabin has trapdoor to root cellar with survival supplies and a +1 Longbow. Following rare blue flowers leads to the fey grove (Potion of Vitality in the fountain). Befriending the Owlbear (DC 18 Animal Handling) grants safe passage."
            locNotes = ""
            
        default:
            break
        }
    }
}




// Error Enum
enum CardCreationError: LocalizedError {
    case invalidData(String)
    var errorDescription: String? {
        switch self {
        case .invalidData(let message): return message
        }
    }
}
