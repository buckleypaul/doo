import SwiftUI

enum DooStyle {
    static func priorityColor(for priority: Int) -> Color {
        switch priority {
        case 0: return .red
        case 1: return .orange
        default: return Color(nsColor: .tertiaryLabelColor)
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
