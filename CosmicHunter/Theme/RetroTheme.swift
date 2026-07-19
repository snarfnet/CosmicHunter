import SwiftUI

enum Retro {
    static let bg = Color(red: 0.05, green: 0.06, blue: 0.10)
    static let panel = Color(red: 0.10, green: 0.12, blue: 0.18)
    static let bezel = Color(red: 0.16, green: 0.18, blue: 0.26)
    static let dial = Color(red: 0.92, green: 0.94, blue: 0.98)
    static let needle = Color(red: 0.30, green: 0.80, blue: 1.00)
    static let lcd = Color(red: 0.45, green: 0.90, blue: 1.00)
    static let lcdDim = Color(red: 0.22, green: 0.42, blue: 0.50)
    static let amber = Color(red: 1.00, green: 0.72, blue: 0.30)
    static let star = Color(red: 0.80, green: 0.85, blue: 1.00)

    static func rateColor(_ rate: Double) -> Color {
        switch rate {
        case ..<3: return lcd
        case ..<10: return Color(red: 0.55, green: 0.95, blue: 0.75)
        case ..<25: return amber
        default: return Color(red: 1.00, green: 0.45, blue: 0.40)
        }
    }
}
