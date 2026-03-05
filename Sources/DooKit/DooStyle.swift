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

    // MARK: - Tag color helpers

    /// Returns a Color from a hex string like "#f4dbd6" or "f4dbd6".
    static func color(fromHex hex: String) -> Color? {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard h.count == 6, let rgb = UInt64(h, radix: 16) else { return nil }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >>  8) & 0xFF) / 255.0
        let b = Double( rgb        & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b)
    }

    /// Returns the assigned color for a tag, or nil if none assigned.
    @MainActor
    static func tagColor(for tag: String, settings: SettingsManager) -> Color? {
        guard let hex = settings.tagColors[tag] else { return nil }
        return color(fromHex: hex)
    }

    /// Returns black or white for maximum contrast against the given hex background.
    static func contrastColor(for hex: String) -> Color {
        let h = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard h.count == 6, let rgb = UInt64(h, radix: 16) else { return .black }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >>  8) & 0xFF) / 255.0
        let b = Double( rgb        & 0xFF) / 255.0
        // sRGB luminance
        func linearize(_ c: Double) -> Double { c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        let luminance = 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
        return luminance > 0.179 ? .black : .white
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
