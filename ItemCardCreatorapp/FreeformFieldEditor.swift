//
//  FreeformFieldEditor.swift
//  ItemCardCreatorapp
//
//  Reusable collapsible field editor for NPC and Location freeform fields.
//  Replaces ~30 lines per field with a single component call.
//

import SwiftUI

struct FreeformFieldEditor: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let charLimit: Int
    @Binding var text: String
    var isRequired: Bool = false
    var startExpanded: Bool = false
    var editorHeight: CGFloat = 80

    @State private var isExpanded: Bool = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 4) {
                TextEditor(text: $text)
                    .frame(height: editorHeight)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(borderColor, lineWidth: borderWidth)
                    )
                    .onChange(of: text) { _, newValue in
                        if newValue.count > charLimit {
                            text = String(newValue.prefix(charLimit))
                        }
                    }
            }
            .padding(.top, 4)
        } label: {
            labelView
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .onAppear {
            isExpanded = startExpanded || isRequired || !text.isEmpty
        }
    }

    // MARK: - Label (visible when collapsed or expanded)

    private var labelView: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(iconColor))

            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)

            Text("– \(subtitle)")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            // Status badge: char count if populated, "Required" if empty + required
            if !text.isEmpty {
                Text("\(text.count)/\(charLimit)")
                    .font(.caption2.monospacedDigit())
                    .foregroundColor(text.count >= charLimit ? .red : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            } else if isRequired {
                Text("Required")
                    .font(.caption2.bold())
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }

    // MARK: - Styling Helpers

    private var borderColor: Color {
        if isRequired && text.isEmpty { return .orange }
        if text.count >= charLimit { return .red }
        return Color.secondary.opacity(0.2)
    }

    private var borderWidth: CGFloat {
        (isRequired && text.isEmpty) ? 2 : 1
    }
}
