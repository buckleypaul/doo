import AppKit
import SwiftUI

private extension Color {
    init(light: Color, dark: Color) {
        self = Color(NSColor(name: nil) { appearance in
            switch appearance.bestMatch(from: [.aqua, .darkAqua]) {
            case .darkAqua: return NSColor(dark)
            default:        return NSColor(light)
            }
        })
    }
}

enum DooStyle {
    // MARK: - Surfaces
    static let background = Color(light: CatppuccinPalette.Latte.base,     dark: CatppuccinPalette.Macchiato.base)
    static let surface    = Color(light: CatppuccinPalette.Latte.mantle,   dark: CatppuccinPalette.Macchiato.mantle)
    static let separator  = Color(light: CatppuccinPalette.Latte.crust,    dark: CatppuccinPalette.Macchiato.crust)
    static let tagBg      = Color(light: CatppuccinPalette.Latte.surface0, dark: CatppuccinPalette.Macchiato.surface0)

    // MARK: - Text
    static let textPrimary   = Color(light: CatppuccinPalette.Latte.text,     dark: CatppuccinPalette.Macchiato.text)
    static let textSecondary = Color(light: CatppuccinPalette.Latte.subtext1, dark: CatppuccinPalette.Macchiato.subtext1)
    static let textTertiary  = Color(light: CatppuccinPalette.Latte.subtext0, dark: CatppuccinPalette.Macchiato.subtext0)
    static let textOverlay   = Color(light: CatppuccinPalette.Latte.overlay1, dark: CatppuccinPalette.Macchiato.overlay1)

    // MARK: - Accent (Mauve)
    static let accent        = Color(light: CatppuccinPalette.Latte.mauve, dark: CatppuccinPalette.Macchiato.mauve)

    // MARK: - Status colors
    static let colorGreen    = Color(light: CatppuccinPalette.Latte.green, dark: CatppuccinPalette.Macchiato.green)
    static let colorRed      = Color(light: CatppuccinPalette.Latte.red,   dark: CatppuccinPalette.Macchiato.red)
    static let colorPeach    = Color(light: CatppuccinPalette.Latte.peach, dark: CatppuccinPalette.Macchiato.peach)

    // MARK: - Priority
    static func priorityColor(for priority: Int) -> Color {
        switch priority {
        case 0:  return colorRed
        case 1:  return colorPeach
        default: return textOverlay
        }
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
    }

    enum Radius {
        static let badge: CGFloat = 4
        static let pill:  CGFloat = 6
        static let card:  CGFloat = 8
        static let panel: CGFloat = 12
    }

    enum Size {
        static let badge: CGFloat = 18
        static let icon:  CGFloat = 16
    }
}

extension View {
    /// Expands a table cell to fill its column and enables full-cell hit-testing.
    func tableCell(alignment: Alignment = .leading) -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .contentShape(Rectangle())
    }
}

struct PriorityBadge: View {
    let priority: Int

    var body: some View {
        let color = DooStyle.priorityColor(for: priority)
        Text("P\(priority)")
            .font(.caption2.weight(.bold))
            .frame(width: DooStyle.Size.badge, height: DooStyle.Size.badge)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(RoundedRectangle(cornerRadius: DooStyle.Radius.badge))
    }
}
