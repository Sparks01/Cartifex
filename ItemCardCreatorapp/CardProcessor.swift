import Foundation
import SwiftUI
import CoreText
import AppKit

struct ProcessedCard: Identifiable {
    let id: UUID
    let item: Card
    let layout: CardLayout
    let pages: [CardPage]
}

struct CardPage: Identifiable {
    let id = UUID()
    let pageNumber: Int
    let totalPages: Int
    
    // RICH TEXT: Used by Standard Cards (CoreText)
    let attributedContent: AttributedString
    
    // RAW TEXT: Used by NPCs (Columns) AND Export/Compatibility
    let description: String
    
    let properties: [ItemProperty]
    let isOverflow: Bool
}

class CardProcessor {
    
    // MARK: - Main Router
    static func process(_ card: Card, layout: CardLayout) -> ProcessedCard {
        // Router: Choose the right engine based on card type
        if card.category == .npc || card.category == .location {
            return processTwoColumn(card, layout: layout)
        } else {
            return processStandard(card, layout: layout)
        }
    }
    
    // MARK: - Engine A: CoreText (Standard)
    private static func processStandard(_ card: Card, layout: CardLayout) -> ProcessedCard {
        // CONSTANTS MUST MATCH ItemCardView.swift EXACTLY
        let headerHeight: CGFloat = 46
        let statsHeight: CGFloat = card.stats.isEmpty ? 0 : 32
        let footerHeight: CGFloat = 26
        let verticalPadding: CGFloat = 12
        let widthPadding: CGFloat = 14
        let contentWidth = layout.width - widthPadding
        let safetyBuffer: CGFloat = 2
        
        let rawText = cleanDescription(card.itemDescription)
        let fullAttributedText = generateRichText(from: rawText, fontSize: (layout == .landscape4x6 ? 11 : 10))
        let framesetter = CTFramesetterCreateWithAttributedString(fullAttributedText)
        
        var pages: [CardPage] = []
        var textRange = CFRangeMake(0, 0)
        let textLength = fullAttributedText.length
        var pageIndex = 1
        
        while textRange.location < textLength {
            let isFirstPage = (pageIndex == 1)
            let currentStatsHeight = isFirstPage ? statsHeight : 0
            
            // Calculate Exact Available Height
            let availableHeight = layout.height - headerHeight - currentStatsHeight - footerHeight - verticalPadding - safetyBuffer
            
            var fitRange = CFRangeMake(0, 0)
            let constraints = CGSize(width: contentWidth, height: availableHeight)
            
            CTFramesetterSuggestFrameSizeWithConstraints(
                framesetter,
                CFRangeMake(textRange.location, textLength - textRange.location),
                nil,
                constraints,
                &fitRange
            )
            
            if fitRange.length > 0 {
                let pageAttributedStr = fullAttributedText.attributedSubstring(from: NSRange(location: fitRange.location, length: fitRange.length))
                let swiftUIAttributed = AttributedString(pageAttributedStr)
                
                pages.append(CardPage(
                    pageNumber: pageIndex,
                    totalPages: 0,
                    attributedContent: swiftUIAttributed,
                    description: pageAttributedStr.string,
                    properties: isFirstPage ? card.properties : [],
                    isOverflow: !isFirstPage
                ))
                
                textRange.location += fitRange.length
                pageIndex += 1
            } else {
                break
            }
        }
        
        if pages.isEmpty {
            pages.append(CardPage(
                pageNumber: 1, totalPages: 1, attributedContent: AttributedString(""), description: "", properties: card.properties, isOverflow: false
            ))
        }
        
        let total = pages.count
        let finalPages = pages.map {
            CardPage(
                pageNumber: $0.pageNumber,
                totalPages: total,
                attributedContent: $0.attributedContent,
                description: $0.description,
                properties: $0.properties,
                isOverflow: $0.isOverflow
            )
        }
        
        return ProcessedCard(id: card.id, item: card, layout: layout, pages: finalPages)
    }
    
    // MARK: - Engine B: Manual Math (NPCs)
    private static func processTwoColumn(_ card: Card, layout: CardLayout) -> ProcessedCard {
        let headerHeight: CGFloat = 46
        let statsHeight: CGFloat = card.stats.isEmpty ? 0 : 32
        let footerHeight: CGFloat = 26
        let bodyPadding: CGFloat = 12
        
        var firstPageLimit = layout.height - headerHeight - statsHeight - footerHeight - bodyPadding
        var overflowPageLimit = layout.height - headerHeight - footerHeight - bodyPadding
        
        firstPageLimit -= 5
        overflowPageLimit -= 5
        
        var currentMaxHeight = firstPageLimit
        let bodyWidth = layout.width - 24
        let fontSize: CGFloat = (layout == .landscape4x6 ? 10 : 9)
        
        var pages: [CardPage] = []
        let paragraphs = card.itemDescription
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        var currentText = ""
        var pageNum = 1
        
        for paragraph in paragraphs {
            let connector = "\n\n"
            let testText = currentText.isEmpty ? paragraph : currentText + connector + paragraph
            
            let measuredHeight = measureTwoColumnHeight(testText, fontSize: fontSize, width: bodyWidth)
            
            if measuredHeight > currentMaxHeight && !currentText.isEmpty {
                pages.append(CardPage(
                    pageNumber: pageNum,
                    totalPages: 0,
                    attributedContent: AttributedString(""),
                    description: currentText,
                    properties: pageNum == 1 ? card.properties : [],
                    isOverflow: pageNum > 1
                ))
                
                pageNum += 1
                currentText = paragraph
                currentMaxHeight = overflowPageLimit
            } else {
                currentText = testText
            }
        }
        
        pages.append(CardPage(
            pageNumber: pageNum,
            totalPages: 0,
            attributedContent: AttributedString(""),
            description: currentText,
            properties: pageNum == 1 ? card.properties : [],
            isOverflow: pageNum > 1
        ))
        
        let total = pages.count
        let finalPages = pages.map {
            CardPage(
                pageNumber: $0.pageNumber,
                totalPages: total,
                attributedContent: $0.attributedContent,
                description: $0.description,
                properties: $0.properties,
                isOverflow: $0.isOverflow
            )
        }
        
        return ProcessedCard(id: card.id, item: card, layout: layout, pages: finalPages)
    }
    
    // MARK: - Shared Helpers
    
    // Rich Text Generator (CoreText Engine)
    private static func generateRichText(from text: String, fontSize: CGFloat) -> NSAttributedString {
        let paragraphs = text.components(separatedBy: "\n\n")
        let finalString = NSMutableAttributedString()
        
        let font = NSFont.systemFont(ofSize: fontSize)
        let gapFont = NSFont.systemFont(ofSize: fontSize * 0.4) // Tiny font for manual gap
        
        for (index, para) in paragraphs.enumerated() {
            var attrPara: NSMutableAttributedString
            do {
                let swiftUIAttributed = try AttributedString(
                    markdown: para,
                    options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                )
                attrPara = NSMutableAttributedString(swiftUIAttributed)
            } catch {
                attrPara = NSMutableAttributedString(string: para)
            }
            
            let range = NSRange(location: 0, length: attrPara.length)
            attrPara.addAttribute(.font, value: font, range: range)
            attrPara.addAttribute(.foregroundColor, value: NSColor.black, range: range)
            
            let style = NSMutableParagraphStyle()
            style.lineSpacing = 1.0
            style.paragraphSpacing = 0  // Keep at 0, we'll handle manually

            attrPara.addAttribute(.paragraphStyle, value: style, range: range)
            finalString.append(attrPara)

            if index < paragraphs.count - 1 {
                let isList = isListItem(para)
                let nextIsList = (index + 1 < paragraphs.count) ? isListItem(paragraphs[index + 1]) : false
                
                if isList && nextIsList {
                    // List → List: Single newline (tight)
                    finalString.append(NSAttributedString(string: "\n", attributes: [.font: font, .paragraphStyle: style]))
                } else {
                    // Para → Para or List → Para: Double newline (gap)
                    finalString.append(NSAttributedString(string: "\n\n", attributes: [.font: font, .paragraphStyle: style]))
                }
            }
        }
        return finalString
    }
    
    // Two-Column Math Logic (NPC Engine)
    private static func measureTwoColumnHeight(_ text: String, fontSize: CGFloat, width: CGFloat) -> CGFloat {
        let columns = splitIntoColumns(text)
        let leftHeight = measureSingleColumn(columns.left, fontSize: fontSize, width: (width - 12) / 2)
        let rightHeight = measureSingleColumn(columns.right, fontSize: fontSize, width: (width - 12) / 2)
        return max(leftHeight, rightHeight)
    }
    
    private static func measureSingleColumn(_ text: String, fontSize: CGFloat, width: CGFloat) -> CGFloat {
        let paragraphs = text.components(separatedBy: "\n\n")
        var totalHeight: CGFloat = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 2
        paragraphStyle.lineSpacing = 0.5
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraphStyle
        ]
        
        for (index, paragraph) in paragraphs.enumerated() {
            if paragraph.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            let t = paragraph.replacingOccurrences(of: "**", with: "")
            let attrString = NSAttributedString(string: t, attributes: attributes)
            let rect = attrString.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading]
            )
            totalHeight += ceil(rect.height)
            if index < paragraphs.count - 1 { totalHeight += paragraphStyle.paragraphSpacing }
        }
        return totalHeight
    }

    private static func splitIntoColumns(_ text: String) -> (left: String, right: String) {
        let paragraphs = text.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var leftColumn: [String] = []
        var rightColumn: [String] = []
        
        for paragraph in paragraphs {
            let lower = paragraph.lowercased()
            if lower.starts(with: "**utility:**") || lower.starts(with: "**stakes:**") || lower.starts(with: "**hazards:**") || lower.starts(with: "**secrets:**") || lower.starts(with: "**notes:**") {
                rightColumn.append(paragraph)
            } else {
                leftColumn.append(paragraph)
            }
        }
        return (left: leftColumn.joined(separator: "\n\n"), right: rightColumn.joined(separator: "\n\n"))
    }
    
    private static func isListItem(_ text: String) -> Bool {
        let t = text.trimmingCharacters(in: .whitespaces)
        return t.starts(with: "*") || t.starts(with: "-") || t.starts(with: "•") || t.firstMatch(of: #/^\d+[\.:]/#) != nil
    }
    
    private static func cleanDescription(_ text: String) -> String {
        let lines = text.replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\r", with: "").components(separatedBy: .newlines)
        var cleaned: [String] = []
        var rows: [(String, String)] = []
        var first = true
        
        for line in lines {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("|") {
                if t.contains("-") && !t.contains(try! Regex("[a-zA-Z0-9]")) { continue }
                var c = t.dropFirst().trimmingCharacters(in: .whitespaces)
                if c.hasSuffix("|") { c = String(c.dropLast()) }
                let cells = c.components(separatedBy: "|").map{ $0.trimmingCharacters(in: .whitespaces) }
                if first { first = false; continue }
                if cells.count >= 2 { rows.append((cells[0], cells[1...].joined(separator: " | "))) }
            } else {
                if !rows.isEmpty { cleaned.append(formatTableRows(rows)); rows=[]; first=true }
                if !t.isEmpty { cleaned.append(t) }
            }
        }
        if !rows.isEmpty { cleaned.append(formatTableRows(rows)) }
        return cleaned.joined(separator: "\n\n")
    }
    
    private static func formatTableRows(_ rows: [(key: String, value: String)]) -> String {
        return rows.map { "**\($0.key)**: \($0.value)" }.joined(separator: "\n\n")
    }
}
