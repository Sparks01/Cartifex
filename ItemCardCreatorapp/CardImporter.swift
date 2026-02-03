//
//  CardImporter.swift
//  ItemCardCreatorapp
//
//  Centralizes card creation and detail-copying logic.
//  Used by CatalogView for imports and quick saves.
//  Designed so the detail-copying can later be reused for in-place editing.
//

import SwiftUI
import SwiftData

struct CardImporter {

    // MARK: - Copy Details (reusable for future editing)

    /// Copies all category-specific details from one card to another.
    /// Call this separately when you need to update an existing card in-place.
    static func copyDetails(from source: Card, to destination: Card) {
        if let m = source.magicItemDetails {
            destination.magicItemDetails = MagicItemDetails(
                type: m.type,
                rarity: m.rarity,
                requiresAttunement: m.requiresAttunement,
                attunementDetail: m.attunementDetail,
                magicBonus: m.magicBonus
            )
        }

        if let w = source.weaponDetails {
            destination.weaponDetails = WeaponDetails(
                damageDice: w.damageDice,
                damageType: w.damageType,
                range: w.range,
                mastery: w.mastery,
                isSimple: w.isSimple,
                properties: w.properties
            )
        }

        if let a = source.armorDetails {
            destination.armorDetails = ArmorDetails(
                ac: a.ac,
                category: a.category,
                stealthDisadvantage: a.stealthDisadvantage,
                strengthReq: a.strengthReq
            )
        }

        if let s = source.spellDetails {
            destination.spellDetails = SpellDetails(
                level: s.level,
                school: s.school,
                castingTime: s.castingTime,
                range: s.range,
                components: s.components,
                duration: s.duration,
                concentration: s.concentration,
                ritual: s.ritual,
                classes: s.classes
            )
        }

        if let n = source.npcDetails {
            destination.npcDetails = NPCDetails(
                ac: n.ac,
                hp: n.hp,
                cr: n.cr,
                type: n.type,
                ancestry: n.ancestry,
                role: n.role,
                archetype: n.archetype,
                faction: n.faction,
                statblockName: n.statblockName,
                tier: n.tier,
                signatureAction: n.signatureAction,
                isCustomStatblock: n.isCustomStatblock,
                persona: n.persona,
                drive: n.drive,
                utility: n.utility,
                stakes: n.stakes,
                partyNotes: n.partyNotes
            )
        }

        if let l = source.locationDetails {
            destination.locationDetails = LocationDetails(
                type: l.type,
                size: l.size,
                difficulty: l.difficulty,
                pointsOfInterest: l.pointsOfInterest,
                hooks: l.hooks,
                hazards: l.hazards,
                secrets: l.secrets,
                notes: l.notes
            )
        }
    }

    // MARK: - Import from Card

    /// Creates a new Card from a catalog Card, optionally assigning it to a collection.
    static func importCard(_ source: Card, collection: CardCollection? = nil) -> Card {
        let newCard = Card(
            title: source.title,
            subtitle: source.subtitle,
            category: source.category,
            description: source.itemDescription,
            source: source.source,
            stats: source.stats,
            properties: source.properties,
            tags: source.tags,
            collection: collection
        )

        copyDetails(from: source, to: newCard)
        return newCard
    }

    // MARK: - Import from Open5eItem (Spells)

    /// Creates a new Card from an Open5e spell, optionally assigning it to a collection.
    static func importSpell(_ spell: Open5eItem, collection: CardCollection? = nil) -> Card? {
        guard let safeName = spell.name else { return nil }
        guard let level = spell.level, let school = spell.school else { return nil }

        let components = spell.components ?? "V, S"
        let spellStats = [
            ItemStat(label: "Level", value: level.replacingOccurrences(of: "-level", with: "")),
            ItemStat(label: "Casting", value: spell.casting_time ?? ""),
            ItemStat(label: "Range", value: spell.range ?? ""),
            ItemStat(label: "Comp", value: components),
            ItemStat(label: "Dur", value: spell.duration ?? "")
        ]

        let newCard = Card(
            title: safeName,
            subtitle: "\(level) \(school)",
            category: .spell,
            description: spell.desc ?? "",
            source: spell.document_title ?? "Open5e",
            stats: spellStats,
            tags: ["Spell", school, level],
            collection: collection
        )

        newCard.spellDetails = SpellDetails(
            level: level,
            school: school,
            castingTime: spell.casting_time ?? "1 Action",
            range: spell.range ?? "Touch",
            components: components,
            duration: spell.duration ?? "Instantaneous",
            concentration: spell.concentration ?? false,
            ritual: spell.ritual ?? false,
            classes: spell.classes ?? ""
        )

        return newCard
    }
}
