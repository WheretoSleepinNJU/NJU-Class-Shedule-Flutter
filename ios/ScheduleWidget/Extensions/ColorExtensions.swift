import SwiftUI

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        // Remove common prefixes and non-alphanumeric characters
        var cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle common prefixes
        if cleanHex.hasPrefix("0x") || cleanHex.hasPrefix("0X") {
            cleanHex = String(cleanHex.dropFirst(2))
        } else if cleanHex.hasPrefix("#") {
            cleanHex = String(cleanHex.dropFirst(1))
        }
        
        // Remove any remaining non-alphanumeric characters
        cleanHex = cleanHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        
        switch cleanHex.count {
        case 3: // RGB (12-bit) - e.g., "F0A"
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit) - e.g., "FF00AA"
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit) - e.g., "FFFF00AA"
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            // Invalid format, fallback to red for debugging
            print("⚠️ [ColorExtension] Invalid hex color format: '\(hex)' -> cleaned: '\(cleanHex)'")
            (a, r, g, b) = (255, 255, 0, 0)  // Red color for debugging
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Enhanced saturation version for widget display
    func enhancedForWidget() -> Color {
        // Convert to HSB and increase saturation
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Increase saturation by 40% but cap at 0.9 to avoid oversaturation
        let enhancedSaturation = min(saturation * 1.4, 0.9)
        // Slightly increase brightness if it's too dark
        let enhancedBrightness = max(brightness, 0.5)
        
        return Color(UIColor(hue: hue, saturation: enhancedSaturation, brightness: enhancedBrightness, alpha: alpha))
    }
}