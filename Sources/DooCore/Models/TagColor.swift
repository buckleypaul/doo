import Foundation

public struct TagColor: Codable, Equatable, Sendable {
    public let name: String
    public let hex: String

    public init(name: String, hex: String) {
        self.name = name
        self.hex = hex
    }

    public static func defaultPalette() -> [TagColor] {
        [
            TagColor(name: "Rosewater", hex: "#f4dbd6"),
            TagColor(name: "Flamingo",  hex: "#f0c6c6"),
            TagColor(name: "Pink",      hex: "#f5bde6"),
            TagColor(name: "Mauve",     hex: "#c6a0f6"),
            TagColor(name: "Red",       hex: "#ed8796"),
            TagColor(name: "Maroon",    hex: "#ee99a0"),
            TagColor(name: "Peach",     hex: "#f5a97f"),
            TagColor(name: "Yellow",    hex: "#eed49f"),
            TagColor(name: "Green",     hex: "#a6da95"),
            TagColor(name: "Teal",      hex: "#8bd5ca"),
            TagColor(name: "Sky",       hex: "#91d7e3"),
            TagColor(name: "Sapphire",  hex: "#7dc4e4"),
            TagColor(name: "Blue",      hex: "#8aadf4"),
            TagColor(name: "Lavender",  hex: "#b7bdf8"),
        ]
    }
}
