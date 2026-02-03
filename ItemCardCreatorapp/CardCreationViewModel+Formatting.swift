//
//  CardCreationViewModel+Formatting.swift
//  ItemCardCreatorapp
//
//  Created by Jose Munoz on 1/28/26.
//

import Foundation
import SwiftUI

// MARK: - Formatting Extensions
extension CardCreationViewModel {
    
    // MARK: - NPC Description Formatter
    func formatNPCDescription() -> String {
        var sections: [String] = []
        
        // Helper to trim whitespace
        func trim(_ str: String) -> String {
            str.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 1. CONCEPT - Main description (Visuals & Role)
        let conceptTrimmed = trim(description)
        if !conceptTrimmed.isEmpty {
            sections.append("**CONCEPT:** \(conceptTrimmed)")
        }
        
        // 2. PERSONA - Voice & Vibe
        let personaTrimmed = trim(npcPersona)
        if !personaTrimmed.isEmpty {
            sections.append("**PERSONA:** \(personaTrimmed)")
        }
        
        // 3. DRIVE - Goals & Motivation (REQUIRED)
        let driveTrimmed = trim(npcDrive)
        if !driveTrimmed.isEmpty {
            sections.append("**DRIVE:** \(driveTrimmed)")
        }
        
        // 4. UTILITY - Info & Assets
        let utilityTrimmed = trim(npcUtility)
        if !utilityTrimmed.isEmpty {
            sections.append("**UTILITY:** \(utilityTrimmed)")
        }
        
        // 5. STAKES - Leverage & Limits
        let stakesTrimmed = trim(npcStakes)
        if !stakesTrimmed.isEmpty {
            sections.append("**STAKES:** \(stakesTrimmed)")
        }
        
        // 6. NOTES - Session Tracking (Party Notes)
        let notesTrimmed = trim(npcPartyNotes)
        if !notesTrimmed.isEmpty {
            sections.append("**NOTES:** \(notesTrimmed)")
        }
        
        // Join with double newlines for proper paragraph breaks
        return sections.joined(separator: "\n\n")
    }
    
    func formatNPCDescriptionAttributed() -> AttributedString {
        // Get the plain text
        let plainText = formatNPCDescription()
        
        // Create paragraph style with reduced spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing = 6
        paragraphStyle.lineSpacing = 1.0
        
        // Create attributed string
        let nsAttributed = NSMutableAttributedString(string: plainText)
        nsAttributed.addAttribute(.paragraphStyle,
                                  value: paragraphStyle,
                                  range: NSRange(location: 0, length: nsAttributed.length))
        
        // Convert to SwiftUI AttributedString
        return AttributedString(nsAttributed)
    }
    
    // MARK: - Location Description Formatter
    func formatLocationDescription() -> String {
        var sections: [String] = []
        
        // Helper to trim whitespace
        func trim(_ str: String) -> String {
            str.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // 1. ATMOSPHERE - Main description (Senses & Mood)
        let atmosphereTrimmed = trim(description)
        if !atmosphereTrimmed.isEmpty {
            sections.append("**ATMOSPHERE:** \(atmosphereTrimmed)")
        }
        
        // 2. POINTS OF INTEREST - Key Locations
        let poiTrimmed = trim(locPointsOfInterest)
        if !poiTrimmed.isEmpty {
            sections.append("**POINTS OF INTEREST:** \(poiTrimmed)")
        }
        
        // 3. HOOKS - Why Players Care
        let hooksTrimmed = trim(locHooks)
        if !hooksTrimmed.isEmpty {
            sections.append("**HOOKS:** \(hooksTrimmed)")
        }
        
        // 4. HAZARDS - Dangers & Challenges
        let hazardsTrimmed = trim(locHazards)
        if !hazardsTrimmed.isEmpty {
            sections.append("**HAZARDS:** \(hazardsTrimmed)")
        }
        
        // 5. SECRETS - Hidden Elements
        let secretsTrimmed = trim(locSecrets)
        if !secretsTrimmed.isEmpty {
            sections.append("**SECRETS:** \(secretsTrimmed)")
        }
        
        // 6. NOTES - Session Tracking
        let notesTrimmed = trim(locNotes)
        if !notesTrimmed.isEmpty {
            sections.append("**NOTES:** \(notesTrimmed)")
        }
        
        // Join with double newlines for proper paragraph breaks
        return sections.joined(separator: "\n\n")
    }
}
