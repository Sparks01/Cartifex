import SwiftUI
import AppKit

struct ItemCardView: View {
    let page: CardPage
    let card: Card
    let layout: CardLayout
    
    // --- Font Sizes ---
    var titleSize: CGFloat { layout == .landscape4x6 ? 18 : 16 }
    var subtitleSize: CGFloat { 9 }
    var bodySize: CGFloat {
        if card.category == .npc || card.category == .location {
            return layout == .landscape4x6 ? 10 : 9
        }
        return layout == .landscape4x6 ? 11 : 10
    }
    
    // --- Layout Constants (SYNCED WITH PROCESSOR) ---
    var maxBodyHeight: CGFloat {
        // 1. Header Area
        // Title(18) + Subtitle(9) + Padding(10+4) + Spacing(2) approx 43.
        // We reserve 46 to be safe.
        let headerHeight: CGFloat = 46
        
        // 2. Stats Area
        // Only on Page 1, if stats exist.
        let hasStats = !card.stats.isEmpty
        let showStats = hasStats && !page.isOverflow
        let statsHeight: CGFloat = showStats ? 32 : 0
        
        // 3. Footer Area
        // Font(8) + Padding(6+6) approx 20.
        // We reserve 26 to be safe.
        let footerHeight: CGFloat = 26
        
        // 4. Body Padding
        // We use .padding(6) on the VStack, so 6 top + 6 bottom = 12.
        let padding: CGFloat = 12
        
        var height = layout.height - headerHeight - statsHeight - footerHeight - padding
        
        if card.category == .npc || card.category == .location {
            let safetyMargin: CGFloat = 5
            height = height - safetyMargin
        }
        
        return height
    }
    
    // --- Colors & Data ---
    private let classColors: [String: Color] = [
        "bard": Color(hex: "EC4899"), "cleric": Color(hex: "fb9700"), "druid": Color(hex: "10B981"),
        "sorcerer": Color(hex: "EF4444"), "warlock": Color(hex: "9333EA"), "wizard": Color(hex: "3B82F6"),
        "artificer": Color(hex: "06B6D4"), "paladin": Color(hex: "e07a00"), "ranger": Color(hex: "22C55E"),
        "barbarian": Color(hex: "991B1B"), "fighter": Color(hex: "78716C"), "monk": Color(hex: "0891B2"),
        "rogue": Color(hex: "6B7280")
    ]
    
    private let commonClasses: [String] = [
        "wizard", "sorcerer", "warlock", "cleric", "druid", "bard", "paladin", "ranger", "barbarian", "fighter", "monk", "rogue"
    ]
    
    var themeColor: Color {
        if card.category == .spell { return getSchoolColor(from: card.spellDetails?.school ?? "") }
        switch card.category {
        case .npc: return Color(hex: "ea580c")
        case .location: return Color(hex: "16a34a")
        case .item: return Color(hex: "4f46e5")
        case .weapon: return Color(hex: "b91c1c")
        case .armor: return Color(hex: "0369a1")
        case .magicItem: return Color(hex: "c026d3")
        default: return .gray
        }
    }
    
    var categoryColor: Color {
        switch card.category {
        case .spell: return Color(hex: "9333ea")
        case .npc: return Color(hex: "ea580c")
        case .location: return Color(hex: "16a34a")
        case .item: return Color(hex: "4f46e5")
        case .weapon: return Color(hex: "b91c1c")
        case .armor: return Color(hex: "0369a1")
        case .magicItem: return Color(hex: "c026d3")
        }
    }
    
    // MARK: - Main Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // 1. Header
            renderHeader()
            
            Rectangle().frame(height: 2).foregroundColor(categoryColor)
            
            // 2. Stats (Page 1 only)
            if !page.isOverflow && !card.stats.isEmpty {
                renderStatsGrid()
            }
            
            // 3. Body Content
            VStack(alignment: .leading, spacing: 4) {
                if !page.description.isEmpty {
                    renderBodyContent()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // TIGHTER PADDING: Reduced from 10 to 6
            .padding(6)
            
            Spacer(minLength: 0)
            
            // 4. Footer
            renderFooter()
        }
        .frame(width: layout.width, height: layout.height, alignment: .topLeading)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func renderHeader() -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: 8) {
                Text(page.isOverflow ? "\(card.title) (Cont.)" : card.title)
                    .font(.system(size: titleSize, weight: .bold, design: .serif))
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                if !page.isOverflow {
                    HStack(spacing: 4) {
                        if (card.magicItemDetails?.requiresAttunement ?? false) ||
                            (card.weaponDetails != nil && card.magicItemDetails?.requiresAttunement == true) ||
                            (card.armorDetails != nil && card.magicItemDetails?.requiresAttunement == true) {
                            BadgeView(text: "A", color: .gray).help("Requires Attunement")
                        }
                        if card.category == .npc, let tier = card.npcDetails?.tier {
                            BadgeView(text: "T\(tier)", color: .gray).help("Tier \(tier)")
                        }
                        if card.category == .location, let difficulty = card.locationDetails?.difficulty {
                            BadgeView(text: "DC \(difficulty)", color: getDCColor(difficulty: difficulty))
                                .help("Difficulty Check: \(difficulty)")
                        }
                        if let spell = card.spellDetails {
                            if spell.concentration { BadgeView(text: "C", color: .gray) }
                            if spell.ritual { BadgeView(text: "R", color: .gray) }
                            Text("SPELL").font(.system(size: 9, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 4).background(categoryColor).foregroundColor(.white).cornerRadius(4)
                        } else {
                            BadgeView(text: card.category.rawValue.uppercased(), color: categoryColor)
                        }
                    }
                }
            }
            
            if !page.isOverflow {
                Text(getSubtitle().uppercased())
                    .font(.system(size: subtitleSize, weight: .bold))
                    .foregroundColor(.gray)
            }
        }
        // TIGHTER HEADER PADDING: Reduced bottom from 6 to 4
        .padding(.horizontal, 10).padding(.top, 10).padding(.bottom, 4)
    }
    
    @ViewBuilder
    private func renderStatsGrid() -> some View {
        HStack(spacing: 0) {
            ForEach(Array(card.stats.prefix(4).enumerated()), id: \.offset) { index, stat in
                VStack(spacing: 2) {
                    Text(stat.label).font(.system(size: 7, weight: .bold)).textCase(.uppercase).foregroundColor(.gray)
                    Text(stat.value).font(.system(size: 9, weight: .semibold)).foregroundColor(.black).multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 6)
                if index < min(3, card.stats.count - 1) { Rectangle().fill(Color.gray.opacity(0.2)).frame(width: 1, height: 20) }
            }
        }
        .background(Color(white: 0.96))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.2)), alignment: .bottom)
    }
    
    @ViewBuilder
    private func renderBodyContent() -> some View {
        if card.category == .npc || card.category == .location {
            // NPC/Location: Use the raw description and split columns visually
            twoColumnNPCBody(text: page.description)
        } else {
            // Standard Cards: Use the precise CoreText layout
            Text(page.attributedContent)
                .frame(maxWidth: .infinity, maxHeight: maxBodyHeight, alignment: .topLeading)
        }
    }
    
    @ViewBuilder
    private func renderFooter() -> some View {
        VStack(spacing: 0) {
            if !page.isOverflow {
                let badges = getBadgesToDisplay()
                if !badges.isEmpty {
                    HStack(spacing: 4) {
                        Spacer()
                        ForEach(badges, id: \.0) { text, color in
                            Text(text)
                                .font(.system(size: 7, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(color)
                                .foregroundColor(.white)
                                .cornerRadius(3)
                        }
                    }
                    .padding(.horizontal, 8).padding(.bottom, 4)
                }
            }
            
            if !page.isOverflow {
                HStack(spacing: 6) {
                    if card.category == .spell {
                        Text(card.spellDetails?.school ?? "").font(.system(size: 9, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2).background(themeColor.opacity(0.8)).foregroundColor(.white).cornerRadius(4)
                        Text(card.spellDetails?.level ?? "").font(.system(size: 9, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2).background(Color.gray).foregroundColor(.white).cornerRadius(4)
                    } else if card.category == .weapon {
                        let weaponPills = getWeaponPills()
                        ForEach(weaponPills, id: \.0) { text, color in
                            Text(text).font(.system(size: 9, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2).background(color).foregroundColor(.white).cornerRadius(4)
                        }
                    } else if card.category == .armor {
                        let armorPills = getArmorPills()
                        ForEach(armorPills, id: \.0) { text, color in
                            Text(text).font(.system(size: 9, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2).background(color).foregroundColor(.white).cornerRadius(4)
                        }
                    } else if card.category == .npc {
                        let npcPills = getNPCPills()
                        ForEach(npcPills, id: \.0) { text, color in
                            Text(text).font(.system(size: 9, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2).background(color).foregroundColor(.white).cornerRadius(4)
                        }
                    } else if card.category == .location {
                        let locationPills = getLocationPills()
                        ForEach(locationPills, id: \.0) { text, color in
                            Text(text).font(.system(size: 9, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2).background(color).foregroundColor(.white).cornerRadius(4)
                        }
                    } else {
                        ForEach(card.tags.prefix(2), id: \.self) { tag in
                            if !shouldSkipTag(tag) {
                                Text(tag.uppercased()).font(.system(size: 9, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 2).background(themeColor.opacity(0.8)).foregroundColor(.white).cornerRadius(4)
                            }
                        }
                    }
                    Spacer()
                    Text(card.source).font(.system(size: 8)).foregroundColor(.gray)
                }
                // TIGHTER FOOTER PADDING: Reduced from 8 to 6
                .padding(6)
                .background(card.category != .spell ? Color(white: 0.98) : Color.clear)
                .overlay(card.category != .spell ? Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.2)).padding(.top, -6) : nil, alignment: .top)
            } else {
                // TIGHTER FOOTER PADDING
                HStack { Spacer(); Text(card.source).font(.system(size: 8)).foregroundColor(.gray) }
                    .padding(6)
                    .background(Color(white: 0.98))
                    .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.2)).padding(.top, -6), alignment: .top)
            }
        }
        .layoutPriority(1)
    }
    
    // MARK: - Helpers & Layout Logic
    
    struct BadgeView: View { let text: String; let color: Color; var body: some View { Text(text.uppercased()).font(.system(size: 8, weight: .bold)).padding(.horizontal, 6).padding(.vertical, 4).background(color).foregroundColor(.white).cornerRadius(4) } }
    
    func getSubtitle() -> String {
        if card.category == .spell, let s = card.spellDetails { return "\(s.level) \(s.school)" }
        if let w = card.weaponDetails {
            let type = w.isSimple ? "Simple" : "Martial"
            if let m = card.magicItemDetails, m.rarity != "Unknown", m.rarity != "Common" { return "\(type) Weapon, \(m.rarity)" }
            return "\(type) Weapon"
        }
        if let a = card.armorDetails {
            if let m = card.magicItemDetails, m.rarity != "Unknown" { return "\(a.category) Armor, \(m.rarity)" }
            return "\(a.category) Armor"
        }
        return card.subtitle
    }
    
    private func getSchoolColor(from school: String) -> Color {
        let lower = school.lowercased()
        if lower.contains("abjuration") { return Color(hex: "3B82F6") }
        if lower.contains("conjuration") { return Color(hex: "F59E0B") }
        if lower.contains("divination") { return Color(hex: "94A3B8") }
        if lower.contains("enchantment") { return Color(hex: "EC4899") }
        if lower.contains("evocation") { return Color(hex: "EF4444") }
        if lower.contains("illusion") { return Color(hex: "9333EA") }
        if lower.contains("necromancy") { return Color(hex: "10B981") }
        if lower.contains("transmutation") { return Color(hex: "CD7F32") }
        return Color(hex: "9333ea")
    }
    
    private func getBadgesToDisplay() -> [(String, Color)] {
        if let spell = card.spellDetails { return getClassBadges(spell.classes) }
        if let magic = card.magicItemDetails, let d = magic.attunementDetail { return getClassBadges(d) }
        if let armor = card.armorDetails { return getArmorClassBadges(category: armor.category) }
        return []
    }
    
    private func getWeaponPills() -> [(String, Color)] {
        guard let weapon = card.weaponDetails else { return [] }
        var pills: [(String, Color)] = []
        let typeName = weapon.isSimple ? "Simple" : "Martial"
        pills.append((typeName, Color.brown))
        for prop in weapon.properties {
            let cleanProp = prop.replacingOccurrences(of: " (1d10)", with: "").replacingOccurrences(of: " (1d8)", with: "")
            if let mastery = weapon.mastery, cleanProp.localizedCaseInsensitiveContains(mastery) { continue }
            pills.append((cleanProp, Color(hex: "15803d")))
        }
        if let mastery = weapon.mastery { pills.append((mastery, Color.orange)) }
        pills.append((weapon.damageType, themeColor))
        return pills
    }
    private func getArmorPills() -> [(String, Color)] {
        guard let armor = card.armorDetails else { return [] }
        var pills: [(String, Color)] = []
        pills.append((armor.category.capitalized, Color.brown))
        if let m = card.magicItemDetails, m.rarity != "Unknown" { pills.append((m.rarity, Color.gray)) }
        return pills
    }
    private func getNPCPills() -> [(String, Color)] {
        var pills: [(String, Color)] = []
        guard let npc = card.npcDetails else { return pills }
        if let ancestry = npc.ancestry, !ancestry.isEmpty { pills.append((ancestry.uppercased(), Color(hex: "14b8a6"))) }
        if let statblock = npc.statblockName, !statblock.isEmpty { pills.append((statblock.uppercased(), Color(hex: "ea580c"))) }
        if let archetype = npc.archetype, !archetype.isEmpty { pills.append((archetype.uppercased(), Color(hex: "6b7280"))) }
        if let faction = npc.faction, !faction.isEmpty { pills.append((faction.uppercased(), Color(hex: "8b5cf6"))) }
        return pills
    }
    
    private func getLocationPills() -> [(String, Color)] {
        var pills: [(String, Color)] = []
        guard let loc = card.locationDetails else { return pills }
        if !loc.type.isEmpty { pills.append((loc.type.uppercased(), Color(hex: "14b8a6"))) }
        if !loc.size.isEmpty { pills.append((loc.size.uppercased(), Color(hex: "ea580c"))) }
        pills.append(("DC \(loc.difficulty)", getDCColor(difficulty: loc.difficulty)))
        return pills
    }
    
    private func getDCColor(difficulty: Int) -> Color {
        switch difficulty {
        case 5...10: return Color(hex: "22c55e")
        case 11...14: return Color(hex: "eab308")
        case 15...18: return Color(hex: "ea580c")
        default: return Color(hex: "dc2626")
        }
    }
    
    // NPC HELPERS (Keep these for the Hybrid NPC layout)
    private func createNPCAttributedString(from text: String, tighterSpacing: Bool = false) -> AttributedString {
        let paragraphs = text.components(separatedBy: "\n\n")
        var result = AttributedString()
        for (index, paragraph) in paragraphs.enumerated() {
            if paragraph.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            var paragraphAttr: AttributedString
            do {
                paragraphAttr = try AttributedString(markdown: paragraph, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace))
            } catch {
                paragraphAttr = AttributedString(paragraph)
            }
            paragraphAttr.font = .system(size: bodySize)
            paragraphAttr.foregroundColor = .black
            result.append(paragraphAttr)
            if index < paragraphs.count - 1 {
                var lineBreak = AttributedString("\n\n")
                lineBreak.font = .system(size: bodySize)
                result.append(lineBreak)
            }
        }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = tighterSpacing ? 2 : 3
        paragraphStyle.lineSpacing = 0.5
        var attributes = AttributeContainer()
        attributes.paragraphStyle = paragraphStyle
        result.mergeAttributes(attributes, mergePolicy: .keepNew)
        return result
    }
    
    @ViewBuilder
    private func twoColumnNPCBody(text: String) -> some View {
        let columns = computeNPCColumns(from: text)
        HStack(alignment: .top, spacing: 12) {
            Text(createNPCAttributedString(from: columns.left, tighterSpacing: true))
                .frame(maxWidth: .infinity, maxHeight: maxBodyHeight, alignment: .topLeading)
            Text(createNPCAttributedString(from: columns.right, tighterSpacing: true))
                .frame(maxWidth: .infinity, maxHeight: maxBodyHeight, alignment: .topLeading)
        }
    }
    
    private func computeNPCColumns(from text: String) -> (left: String, right: String) {
        let paragraphs = text.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var leftColumn: [String] = []
        var rightColumn: [String] = []
        for paragraph in paragraphs {
            let lower = paragraph.lowercased()
            if lower.starts(with: "**utility:**") ||
                lower.starts(with: "**stakes:**") ||
                lower.starts(with: "**hazards:**") ||
                lower.starts(with: "**secrets:**") ||
                lower.starts(with: "**notes:**") {
                rightColumn.append(paragraph)
            } else {
                leftColumn.append(paragraph)
            }
        }
        return (left: leftColumn.joined(separator: "\n\n"), right: rightColumn.joined(separator: "\n\n"))
    }
    
    private func getArmorClassBadges(category: String) -> [(String, Color)] {
        let cat = category.lowercased()
        var classes: [String] = []
        if cat.contains("shield") { classes = ["Barbarian", "Cleric", "Druid", "Fighter", "Paladin", "Ranger"] }
        else if cat.contains("heavy") { classes = ["Fighter", "Paladin"] }
        else if cat.contains("medium") { classes = ["Barbarian", "Cleric", "Druid", "Fighter", "Paladin", "Ranger"] }
        return getClassBadges(classes.joined(separator: ", "))
    }
    
    private func getClassBadges(_ text: String) -> [(String, Color)] {
        var foundBadges: [(String, Color)] = []
        let lowerText = text.lowercased()
        for (className, color) in classColors {
            if lowerText.contains(className) {
                let abbrev: String
                switch className {
                case "barbarian": abbrev = "BAR"
                case "bard": abbrev = "BRD"
                case "cleric": abbrev = "CLR"
                case "druid": abbrev = "DRU"
                case "fighter": abbrev = "FTR"
                case "monk": abbrev = "MNK"
                case "paladin": abbrev = "PAL"
                case "ranger": abbrev = "RGR"
                case "rogue": abbrev = "ROG"
                case "sorcerer": abbrev = "SOR"
                case "warlock": abbrev = "WLK"
                case "wizard": abbrev = "WIZ"
                case "artificer": abbrev = "ART"
                default: abbrev = String(className.prefix(3)).uppercased()
                }
                foundBadges.append((abbrev, color))
            }
        }
        return foundBadges.sorted { $0.0 < $1.0 }
    }
    
    private func shouldSkipTag(_ tag: String) -> Bool {
        let lowercasedTag = tag.lowercased()
        if card.category == .spell && lowercasedTag == "spell" { return true }
        if lowercasedTag == card.category.rawValue.lowercased() { return true }
        if commonClasses.contains(lowercasedTag) { return true }
        return false
    }
}
