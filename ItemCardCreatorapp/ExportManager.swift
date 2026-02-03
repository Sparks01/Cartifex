//
//  ExportManager.swift
//  ItemCardCreatorapp
//
//  Handles PDF export, image export, and printing for card collections.
//  Uses PDFPage subclass for proper page rendering and layout control.
//

import SwiftUI
import PDFKit
import AppKit
import UniformTypeIdentifiers
import Combine
@preconcurrency import Quartz

@MainActor
class ExportManager: ObservableObject {
    static let shared = ExportManager()
    private init() {}
    
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    @Published var lastExportMessage = ""
    
    // MARK: - Export Page Sizes
    
    enum ExportPageSize: String, CaseIterable {
        case cardStock      = "3.5×5 Card Stock"
        case index4x6       = "4×6 Index Card"
        case letterTiled    = "Letter - Multiple Cards"
        case letterTwo      = "Letter - 2 Cards"
        case a4Tiled        = "A4 - Multiple Cards"
        
        /// Page dimensions in points (72pt = 1 inch)
        var size: CGSize {
            switch self {
            case .cardStock:    return CGSize(width: 360, height: 252)   // 5" × 3.5" landscape
            case .index4x6:     return CGSize(width: 432, height: 288)   // 6" × 4" landscape
            case .letterTiled:  return CGSize(width: 612, height: 792)   // 8.5" × 11" portrait
            case .letterTwo:    return CGSize(width: 792, height: 612)   // 11" × 8.5" landscape
            case .a4Tiled:      return CGSize(width: 595, height: 842)   // A4 portrait
            }
        }
        
        var cardsPerPage: Int {
            switch self {
            case .cardStock, .index4x6: return 1
            case .letterTwo: return 2
            case .letterTiled, .a4Tiled: return 4  // 2×2 grid
            }
        }
        
        var isLandscape: Bool {
            switch self {
            case .cardStock, .index4x6, .letterTwo: return true
            case .letterTiled, .a4Tiled: return false
            }
        }
    }
    
    // MARK: - Render Cards to Images
    
    private func renderCardsToImages(items: [Card], layout: CardLayout) async -> [NSImage] {
        var images: [NSImage] = []
        let total = items.count
        
        for (index, card) in items.enumerated() {
            await MainActor.run {
                exportProgress = Double(index) / Double(total)
                lastExportMessage = "Rendering \(card.title)..."
            }
            
            let processed = CardProcessor.process(card, layout: layout)
            
            for page in processed.pages {
                let cardView = ItemCardView(page: page, card: processed.item, layout: layout)
                    .frame(width: layout.width, height: layout.height)
                
                let renderer = ImageRenderer(content: cardView)
                renderer.scale = 2.0
                
                if let image = renderer.nsImage {
                    images.append(image)
                }
            }
            
            // Small delay to keep UI responsive
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        
        return images
    }
    
    // MARK: - Create PDF Document
    
    private func createPDFDocument(images: [NSImage], layout: CardLayout, pageSize: ExportPageSize) -> PDFDocument? {
        let pdfDocument = PDFDocument()
        let cardsPerPage = pageSize.cardsPerPage
        
        for i in stride(from: 0, to: images.count, by: cardsPerPage) {
            let imagesForPage = Array(images[i..<min(i + cardsPerPage, images.count)])
            if let page = CardPDFPage(images: imagesForPage, cardLayout: layout, pageSize: pageSize) {
                pdfDocument.insert(page, at: pdfDocument.pageCount)
            }
        }
        
        return pdfDocument.pageCount > 0 ? pdfDocument : nil
    }
    
    // MARK: - Print Cards
    
    func printCards(items: [Card], layout: CardLayout, pageSize: ExportPageSize = .cardStock) async {
        isExporting = true
        exportProgress = 0.0
        lastExportMessage = "Preparing print job..."
        
        let images = await renderCardsToImages(items: items, layout: layout)
        
        guard let pdfDocument = createPDFDocument(images: images, layout: layout, pageSize: pageSize) else {
            lastExportMessage = "Failed to generate print data."
            isExporting = false
            return
        }
        
        lastExportMessage = "Opening print dialog..."
        
        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
        printInfo.paperSize = pageSize.size
        printInfo.orientation = pageSize.isLandscape ? .landscape : .portrait
        printInfo.topMargin = 9
        printInfo.bottomMargin = 9
        printInfo.leftMargin = 9
        printInfo.rightMargin = 9
        
        guard let printOperation = pdfDocument.printOperation(for: printInfo, scalingMode: .pageScaleNone, autoRotate: false) else {
            lastExportMessage = "Failed to create print operation."
            isExporting = false
            return
        }
        
        printOperation.showsPrintPanel = true
        printOperation.showsProgressPanel = true
        printOperation.run()
        
        isExporting = false
        lastExportMessage = "Print dialog completed."
    }
    
    // MARK: - Save PDF
    
    func savePDF(items: [Card], layout: CardLayout, pageSize: ExportPageSize = .cardStock) async {
        isExporting = true
        exportProgress = 0.0
        lastExportMessage = "Preparing PDF..."
        
        // Show save panel first
        guard let saveURL = await showSavePicker(title: "Export Cards to PDF", filename: "RPG_Cards.pdf", type: .pdf) else {
            lastExportMessage = "Export cancelled."
            isExporting = false
            return
        }
        
        let images = await renderCardsToImages(items: items, layout: layout)
        
        guard let pdfDocument = createPDFDocument(images: images, layout: layout, pageSize: pageSize) else {
            lastExportMessage = "Failed to create PDF."
            isExporting = false
            return
        }
        
        lastExportMessage = "Saving PDF..."
        
        let success = pdfDocument.write(to: saveURL)
        
        isExporting = false
        if success {
            lastExportMessage = "PDF saved successfully."
            NSWorkspace.shared.activateFileViewerSelecting([saveURL])
        } else {
            lastExportMessage = "Failed to save PDF."
        }
    }
    
    // MARK: - Batch Export by Category
    
    func exportByCategory(items: [Card], layout: CardLayout, pageSize: ExportPageSize = .cardStock) async {
        isExporting = true
        exportProgress = 0.0
        lastExportMessage = "Choose export folder..."
        
        guard let folderURL = await showFolderPicker(title: "Choose Export Folder", message: "A separate PDF will be created for each card category.") else {
            lastExportMessage = "Export cancelled."
            isExporting = false
            return
        }
        
        let grouped = Dictionary(grouping: items) { $0.category }
        var savedCount = 0
        let totalCategories = grouped.count
        
        for (index, (category, cards)) in grouped.enumerated() {
            await MainActor.run {
                exportProgress = Double(index) / Double(totalCategories)
                lastExportMessage = "Exporting \(category.rawValue) cards..."
            }
            
            let images = await renderCardsToImages(items: cards, layout: layout)
            
            guard let pdfDocument = createPDFDocument(images: images, layout: layout, pageSize: pageSize) else {
                continue
            }
            
            let url = folderURL.appendingPathComponent("\(category.rawValue)_Cards.pdf")
            if pdfDocument.write(to: url) {
                savedCount += 1
            }
        }
        
        isExporting = false
        if savedCount > 0 {
            lastExportMessage = "Exported \(savedCount) PDF files."
            NSWorkspace.shared.open(folderURL)
        } else {
            lastExportMessage = "No PDFs were exported."
        }
    }
    
    // MARK: - Image Export (PNG)
    
    func saveImages(items: [Card], layout: CardLayout) async {
        isExporting = true
        exportProgress = 0.0
        lastExportMessage = "Preparing images..."
        
        let images = await renderCardsToImages(items: items, layout: layout)
        
        guard !images.isEmpty else {
            lastExportMessage = "No cards to export."
            isExporting = false
            return
        }
        
        if images.count == 1 {
            // Single image → save panel
            guard let url = await showSavePicker(title: "Export Card Image", filename: "Card.png", type: .png) else {
                lastExportMessage = "Export cancelled."
                isExporting = false
                return
            }
            
            writePNG(images[0], to: url)
            lastExportMessage = "Image saved successfully."
            NSWorkspace.shared.activateFileViewerSelecting([url])
        } else {
            // Multiple images → folder picker
            guard let folder = await showFolderPicker(title: "Choose Export Folder", message: "\(images.count) images will be saved as PNG files.") else {
                lastExportMessage = "Export cancelled."
                isExporting = false
                return
            }
            
            for (index, image) in images.enumerated() {
                let url = folder.appendingPathComponent("Card_\(index + 1).png")
                writePNG(image, to: url)
                
                await MainActor.run {
                    exportProgress = Double(index + 1) / Double(images.count)
                    lastExportMessage = "Saving image \(index + 1) of \(images.count)..."
                }
            }
            
            lastExportMessage = "Exported \(images.count) images."
            NSWorkspace.shared.open(folder)
        }
        
        isExporting = false
    }
    
    // MARK: - Helpers
    
    private func writePNG(_ image: NSImage, to url: URL) {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .png, properties: [:]) else { return }
        try? data.write(to: url)
    }
    
    private func showSavePicker(title: String, filename: String, type: UTType) async -> URL? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let panel = NSSavePanel()
                panel.title = title
                panel.nameFieldStringValue = filename
                panel.allowedContentTypes = [type]
                panel.canCreateDirectories = true
                
                panel.begin { response in
                    continuation.resume(returning: response == .OK ? panel.url : nil)
                }
            }
        }
    }
    
    private func showFolderPicker(title: String, message: String) async -> URL? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let panel = NSOpenPanel()
                panel.title = title
                panel.message = message
                panel.canCreateDirectories = true
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                
                panel.begin { response in
                    continuation.resume(returning: response == .OK ? panel.url : nil)
                }
            }
        }
    }
    
    // MARK: - Public Helper for UI
    
    static func cardsPerPage(layout: CardLayout, pageSize: ExportPageSize) -> Int {
        return pageSize.cardsPerPage
    }
}

// MARK: - Custom PDFPage Subclass

private class CardPDFPage: PDFPage {
    private let images: [NSImage]
    private let cardLayout: CardLayout
    private let pageSize: ExportManager.ExportPageSize
    
    init?(images: [NSImage], cardLayout: CardLayout, pageSize: ExportManager.ExportPageSize) {
        guard !images.isEmpty else { return nil }
        self.images = images
        self.cardLayout = cardLayout
        self.pageSize = pageSize
        super.init()
    }
    
    override func bounds(for box: PDFDisplayBox) -> NSRect {
        return NSRect(origin: .zero, size: pageSize.size)
    }
    
    override func draw(with box: PDFDisplayBox, to context: CGContext) {
        NSGraphicsContext.saveGraphicsState()
        let graphicsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = graphicsContext
        
        let pageRect = bounds(for: box)
        
        // Draw white background
        NSColor.white.setFill()
        pageRect.fill()
        
        switch pageSize {
        case .cardStock, .index4x6:
            drawSingleCard(in: pageRect)
            
        case .letterTwo:
            drawTwoCards(in: pageRect)
            
        case .letterTiled, .a4Tiled:
            drawTiledCards(in: pageRect)
        }
        
        NSGraphicsContext.restoreGraphicsState()
    }
    
    private func drawSingleCard(in pageRect: NSRect) {
        guard let image = images.first else { return }
        
        let printableRect = pageRect.insetBy(dx: 9, dy: 9)
        let cardAspect = image.size.width / image.size.height
        
        var cardWidth = printableRect.width
        var cardHeight = cardWidth / cardAspect
        
        if cardHeight > printableRect.height {
            cardHeight = printableRect.height
            cardWidth = cardHeight * cardAspect
        }
        
        let drawRect = NSRect(
            x: (pageRect.width - cardWidth) / 2,
            y: (pageRect.height - cardHeight) / 2,
            width: cardWidth,
            height: cardHeight
        )
        
        image.draw(in: drawRect)
    }
    
    private func drawTwoCards(in pageRect: NSRect) {
        let spacing: CGFloat = 18
        let margin: CGFloat = 18
        
        // Calculate card size to fit two cards horizontally
        let availableWidth = pageRect.width - (margin * 2) - spacing
        let cardWidth = availableWidth / 2
        
        // Maintain aspect ratio
        guard let firstImage = images.first else { return }
        let cardAspect = firstImage.size.width / firstImage.size.height
        var cardHeight = cardWidth / cardAspect
        
        // Ensure it fits vertically
        let maxHeight = pageRect.height - (margin * 2)
        if cardHeight > maxHeight {
            cardHeight = maxHeight
        }
        
        let totalWidth = (cardWidth * 2) + spacing
        var x = (pageRect.width - totalWidth) / 2
        let y = (pageRect.height - cardHeight) / 2
        
        for image in images {
            let drawRect = NSRect(x: x, y: y, width: cardWidth, height: cardHeight)
            image.draw(in: drawRect)
            x += cardWidth + spacing
        }
    }
    
    private func drawTiledCards(in pageRect: NSRect) {
        let margin: CGFloat = 18
        let spacing: CGFloat = 12
        
        // 2×2 grid
        let columns = 2
        let rows = 2
        
        // Calculate card size
        let availableWidth = pageRect.width - (margin * 2) - (spacing * CGFloat(columns - 1))
        let availableHeight = pageRect.height - (margin * 2) - (spacing * CGFloat(rows - 1))
        
        let cardWidth = availableWidth / CGFloat(columns)
        let cardHeight = availableHeight / CGFloat(rows)
        
        // Use smaller dimension to maintain aspect ratio
        guard let firstImage = images.first else { return }
        let cardAspect = firstImage.size.width / firstImage.size.height
        
        var finalWidth = cardWidth
        var finalHeight = finalWidth / cardAspect
        
        if finalHeight > cardHeight {
            finalHeight = cardHeight
            finalWidth = finalHeight * cardAspect
        }
        
        // Center the grid
        let totalGridWidth = (finalWidth * CGFloat(columns)) + (spacing * CGFloat(columns - 1))
        let totalGridHeight = (finalHeight * CGFloat(rows)) + (spacing * CGFloat(rows - 1))
        let startX = (pageRect.width - totalGridWidth) / 2
        let startY = (pageRect.height - totalGridHeight) / 2
        
        for (index, image) in images.enumerated() {
            let col = index % columns
            let row = index / columns
            
            let x = startX + CGFloat(col) * (finalWidth + spacing)
            // PDF coordinates: y increases upward, so row 0 is at top
            let y = startY + CGFloat(rows - 1 - row) * (finalHeight + spacing)
            
            let drawRect = NSRect(x: x, y: y, width: finalWidth, height: finalHeight)
            image.draw(in: drawRect)
        }
    }
}
