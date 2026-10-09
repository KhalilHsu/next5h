import SwiftUI
import AppKit

enum Next5hTheme {
    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let value = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            return NSColor(srgbRed: Double((value >> 16) & 255) / 255,
                           green: Double((value >> 8) & 255) / 255,
                           blue: Double(value & 255) / 255, alpha: 1)
        })
    }

    static let background = adaptive(0xFAFAFA, 0x18181A)
    static let chrome = adaptive(0xFFFFFF, 0x202022)
    static let surface = adaptive(0xFFFFFF, 0x252527)
    static let subtle = adaptive(0xF5F5F6, 0x2B2B2E)
    static let hover = adaptive(0xECECEE, 0x353539)
    static let ink = adaptive(0x242427, 0xF4F4F5)
    static let secondary = adaptive(0x717177, 0xA6A6AC)
    static let border = adaptive(0xE5E5E8, 0x3C3C41)
    static let accent = adaptive(0x2864E8, 0x8DAFFF)
    static let accentHover = adaptive(0x1955D4, 0xB2C9FF)
    static let onAccent = adaptive(0xFFFFFF, 0x142443)
    static let mint = adaptive(0x198568, 0x66D2AE)
    static let warning = adaptive(0xB86A13, 0xF4B86A)
}

extension View {
    func next5hSurface(padding: CGFloat = 16) -> some View {
        self.padding(padding)
            .background(Next5hTheme.surface, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Next5hTheme.border, lineWidth: 1))
    }

    func next5hFormSection() -> some View {
        self.padding(.vertical, 12)
            .overlay(alignment: .bottom) { Rectangle().fill(Next5hTheme.border).frame(height: 1) }
    }
}
