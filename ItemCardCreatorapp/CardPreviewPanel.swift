//
//  CardPreviewPanel.swift
//  ItemCardCreatorapp
//
//  Live preview panel that renders the current form state as an actual card.
//  Uses the same CardProcessor + ItemCardView pipeline as the grid.
//

import SwiftUI

struct CardPreviewPanel: View {
    let viewModel: CardCreationViewModel
    let layout: CardLayout
    
    @State private var currentPageIndex: Int = 0
    @State private var processedCard: ProcessedCard? = nil
    
    // Track form changes for debounced rebuild
    private var formFingerprint: String {
        // Concatenate key fields to detect changes
        [
            viewModel.title,
            viewModel.description,
            viewModel.category.rawValue,
            viewModel.source,
            // Category-specific fields
            viewModel.itemType, viewModel.itemRarity,
            viewModel.requiresAttunement.description,
            viewModel.magicBonus, viewModel.attunementDetail,
            viewModel.spellLevel, viewModel.spellSchool,
            viewModel.castingTime, viewModel.range,
            viewModel.components, viewModel.duration,
            viewModel.concentration.description, viewModel.ritual.description,
            viewModel.classes,
            viewModel.npcAc, viewModel.npcHp, viewModel.npcCr, viewModel.npcSub,
            viewModel.npcAncestry, viewModel.npcRole,
            viewModel.npcArchetype?.rawValue ?? "",
            viewModel.npcFaction, viewModel.npcStatblockName ?? "",
            viewModel.npcPersona, viewModel.npcDrive,
            viewModel.npcUtility, viewModel.npcStakes, viewModel.npcPartyNotes,
            viewModel.locType, viewModel.locSize, String(viewModel.locDifficulty),
            viewModel.locPointsOfInterest, viewModel.locHooks,
            viewModel.locHazards, viewModel.locSecrets, viewModel.locNotes,
            viewModel.damageDice, viewModel.damageType,
            viewModel.weaponProperties, viewModel.mastery,
            viewModel.isSimple.description, viewModel.weaponRange,
            viewModel.armorACValue, viewModel.armorCategoryType,
            viewModel.stealthDisadvantage.description,
            String(viewModel.strengthReq ?? 0),
            viewModel.itemCost
        ].joined(separator: "|")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(.secondary)
                Text("Live Preview")
                    .font(.headline)
                
                Spacer()
                
                // Layout indicator
                Text(layout.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                
                // Page count
                if let processed = processedCard, processed.pages.count > 1 {
                    Text("\(currentPageIndex + 1) of \(processed.pages.count)")
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .foregroundColor(.orange)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Card preview area
            if let processed = processedCard, !processed.pages.isEmpty {
                let pages = processed.pages
                let safeIndex = min(currentPageIndex, pages.count - 1)
                let page = pages[safeIndex]
                
                ScrollView {
                    VStack(spacing: 16) {
                        // The actual card rendered at full size, then scaled to fit
                        cardRenderer(page: page, card: processed.item)
                            .padding(.top, 20)
                        
                        // Page navigation
                        if pages.count > 1 {
                            pageControls(pageCount: pages.count)
                        }
                        
                        // Info bar
                        infoBar(processed: processed)
                            .padding(.bottom, 20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            } else {
                emptyPreviewState
            }
        }
        .task(id: formFingerprint) {
            // Debounce: 200ms delay, auto-cancelled if fingerprint changes again
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            rebuildPreview()
        }
        .onChange(of: layout) { _, _ in
            rebuildPreview()
        }
        .onAppear {
            rebuildPreview()
        }
    }
    
    // MARK: - Card Renderer
    
    @ViewBuilder
    private func cardRenderer(page: CardPage, card: Card) -> some View {
        GeometryReader { geo in
            let availableWidth = geo.size.width - 40 // 20pt padding each side
            let scale = min(availableWidth / layout.width, 1.0) // Never scale up
            
            HStack {
                Spacer()
                ItemCardView(page: page, card: card, layout: layout)
                    .scaleEffect(scale, anchor: .top)
                    .frame(width: layout.width * scale, height: layout.height * scale)
                Spacer()
            }
        }
        .frame(height: cardDisplayHeight)
    }
    
    private var cardDisplayHeight: CGFloat {
        // Calculate approximate scaled height for the GeometryReader frame
        // We'll use a reasonable estimate; actual scale depends on container width
        return layout.height * 0.85 + 20
    }
    
    // MARK: - Page Controls
    
    @ViewBuilder
    private func pageControls(pageCount: Int) -> some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    currentPageIndex = max(0, currentPageIndex - 1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.bold())
            }
            .disabled(currentPageIndex == 0)
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            HStack(spacing: 4) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Circle()
                        .fill(index == currentPageIndex ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                currentPageIndex = index
                            }
                        }
                }
            }
            
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    currentPageIndex = min(pageCount - 1, currentPageIndex + 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.bold())
            }
            .disabled(currentPageIndex >= pageCount - 1)
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
    
    // MARK: - Info Bar
    
    @ViewBuilder
    private func infoBar(processed: ProcessedCard) -> some View {
        let card = processed.item
        let pageCount = processed.pages.count
        let charCount = card.itemDescription.count
        
        HStack(spacing: 16) {
            // Page count indicator
            Label(
                pageCount == 1 ? "Single card" : "\(pageCount) cards",
                systemImage: pageCount == 1 ? "checkmark.circle" : "doc.on.doc"
            )
            .font(.caption)
            .foregroundColor(pageCount == 1 ? .green : .orange)
            
            // Character count
            Label("\(charCount) chars", systemImage: "character.cursor.ibeam")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Category
            Label(card.category.rawValue, systemImage: categoryIcon(card.category))
                .font(.caption.bold())
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
    
    // MARK: - Empty State
    
    private var emptyPreviewState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "rectangle.dashed")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))
            Text("Card Preview")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Start filling out the form to see\na live preview of your card here.")
                .font(.caption)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Preview Logic
    
    private func rebuildPreview() {
        guard let card = viewModel.buildPreviewCard() else {
            processedCard = nil
            return
        }
        
        let processed = CardProcessor.process(card, layout: layout)
        processedCard = processed
        
        // Clamp page index if pages changed
        if currentPageIndex >= processed.pages.count {
            currentPageIndex = max(0, processed.pages.count - 1)
        }
    }
    
    // MARK: - Helpers
    
    private func categoryIcon(_ category: CardCategory) -> String {
        switch category {
        case .spell: return "sparkles"
        case .npc: return "person.crop.circle"
        case .location: return "map"
        case .item: return "cube"
        case .weapon: return "figure.fencing"
        case .armor: return "shield"
        case .magicItem: return "wand.and.stars"
        }
    }
}
