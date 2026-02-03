//
//  ExportOptionsView.swift
//  ItemCardCreatorapp
//
//  Export options sheet: PDF, Print, or Image export with
//  page size selection, organization, and preview info.
//

import SwiftUI

struct ExportOptionsView: View {
    let cards: [Card]
    let layout: CardLayout
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPageSize: ExportManager.ExportPageSize = .cardStock
    @State private var exportMethod: ExportMethod = .pdf
    @State private var organizationMethod: OrganizationMethod = .single
    
    // MARK: - Enums
    
    enum ExportMethod: String, CaseIterable {
        case pdf   = "Save as PDF"
        case print = "Print Directly"
        case image = "Save as Images"
        
        var icon: String {
            switch self {
            case .pdf:   return "doc.fill"
            case .print: return "printer.fill"
            case .image: return "photo.fill"
            }
        }
        
        var description: String {
            switch self {
            case .pdf:   return "Export to PDF file for printing or sharing"
            case .print: return "Send directly to your printer"
            case .image: return "Export each card as a high-resolution PNG"
            }
        }
    }
    
    enum OrganizationMethod: String, CaseIterable {
        case single     = "Single File"
        case byCategory = "By Category"
        
        var icon: String {
            switch self {
            case .single:     return "doc"
            case .byCategory: return "folder"
            }
        }
        
        var description: String {
            switch self {
            case .single:     return "All cards in one file"
            case .byCategory: return "Separate file for each category"
            }
        }
    }
    
    // MARK: - Computed
    
    private var showPageSize: Bool { exportMethod != .image }
    private var showOrganization: Bool { exportMethod == .pdf }
    
    private var cardsPerPage: Int {
        selectedPageSize.cardsPerPage
    }
    
    private var estimatedPages: Int {
        let cpp = cardsPerPage
        guard cpp > 0 else { return cards.count }
        return (cards.count + cpp - 1) / cpp
    }
    
    private var categoryCount: Int {
        Set(cards.map { $0.category }).count
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("Export Cards")
                        .font(.title)
                        .bold()
                    
                    Text("\(cards.count) card\(cards.count == 1 ? "" : "s") selected for export")
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // --- Export Method ---
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Export Method")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ForEach(ExportMethod.allCases, id: \.self) { method in
                                ExportOptionCard(
                                    title: method.rawValue,
                                    description: method.description,
                                    icon: method.icon,
                                    isSelected: exportMethod == method
                                ) {
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        exportMethod = method
                                    }
                                }
                            }
                        }
                        
                        // --- Page Size (PDF & Print only) ---
                        if showPageSize {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Page Size")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(ExportManager.ExportPageSize.allCases, id: \.self) { size in
                                        let cpp = size.cardsPerPage
                                        CardSizeOption(
                                            size: size,
                                            isSelected: selectedPageSize == size,
                                            subtitle: cpp > 1 ? "\(cpp) cards/page" : nil
                                        ) {
                                            selectedPageSize = size
                                        }
                                    }
                                }
                            }
                        }
                        
                        // --- Organization (PDF only) ---
                        if showOrganization {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Organization")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                ForEach(OrganizationMethod.allCases, id: \.self) { method in
                                    ExportOptionCard(
                                        title: method.rawValue,
                                        description: method.description,
                                        icon: method.icon,
                                        isSelected: organizationMethod == method
                                    ) {
                                        organizationMethod = method
                                    }
                                }
                            }
                        }
                        
                        // --- Export Preview ---
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Export Preview")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            InfoCard {
                                VStack(alignment: .leading, spacing: 8) {
                                    InfoRow(label: "Cards", value: "\(cards.count)")
                                    InfoRow(label: "Layout", value: layout.rawValue)
                                    
                                    switch exportMethod {
                                    case .pdf:
                                        InfoRow(label: "Page Size", value: selectedPageSize.rawValue)
                                        if cardsPerPage > 1 {
                                            InfoRow(label: "Cards/Page", value: "\(cardsPerPage)")
                                        }
                                        InfoRow(label: "Est. Pages", value: "~\(estimatedPages)")
                                        if organizationMethod == .byCategory {
                                            InfoRow(label: "Files", value: "\(categoryCount) PDF\(categoryCount == 1 ? "" : "s")")
                                        }
                                        
                                    case .print:
                                        InfoRow(label: "Paper Size", value: selectedPageSize.rawValue)
                                        if cardsPerPage > 1 {
                                            InfoRow(label: "Cards/Page", value: "\(cardsPerPage)")
                                        }
                                        InfoRow(label: "Est. Pages", value: "~\(estimatedPages)")
                                        
                                    case .image:
                                        InfoRow(label: "Format", value: "PNG")
                                        InfoRow(label: "Resolution", value: "\(Int(layout.width * 2))×\(Int(layout.height * 2))px")
                                        InfoRow(label: "Images", value: "\(cards.count)+")
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
                
                // --- Action Buttons ---
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(action: performExport) {
                        HStack {
                            Image(systemName: exportMethod.icon)
                            Text(exportMethod.rawValue)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(cards.isEmpty)
                }
                .padding()
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    // MARK: - Export Action
    
    private func performExport() {
        let manager = ExportManager.shared
        
        // Dismiss first, then run async export
        dismiss()
        
        Task {
            switch exportMethod {
            case .pdf:
                if organizationMethod == .byCategory {
                    await manager.exportByCategory(items: cards, layout: layout, pageSize: selectedPageSize)
                } else {
                    await manager.savePDF(items: cards, layout: layout, pageSize: selectedPageSize)
                }
                
            case .print:
                await manager.printCards(items: cards, layout: layout, pageSize: selectedPageSize)
                
            case .image:
                await manager.saveImages(items: cards, layout: layout)
            }
        }
    }
}

// MARK: - Supporting Views

struct ExportOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .white : .blue)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct CardSizeOption: View {
    let size: ExportManager.ExportPageSize
    let isSelected: Bool
    var subtitle: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.secondary.opacity(0.15))
                    .frame(height: 52)
                    .overlay(
                        Text(size.rawValue)
                            .font(.caption)
                            .bold()
                            .foregroundStyle(isSelected ? .white : .primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                    )
                
                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .blue : .secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct InfoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color.blue.opacity(0.08))
            .cornerRadius(12)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
        .font(.caption)
    }
}
