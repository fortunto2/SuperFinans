//
//  Color+Theme.swift
//  SuperFinans
//
//  App color palette — navy & mint theme with hex initializers.
//

import SwiftUI

// MARK: - Hex Initializer

extension Color {
    /// Initialize Color from hex value
    init(hex: UInt) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }

    /// Initialize Color from hex string (e.g., "#1A2B3C" or "1A2B3C")
    init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(hex: UInt(int))
    }
}

// MARK: - Brand Colors

extension Color {
    // Primary
    static let navyPrimary = Color(hex: 0x0A1628)
    static let navySecondary = Color(hex: 0x1B2A4A)
    static let navyCard = Color(hex: 0x1E3055)

    // Accent — Mint
    static let goalMint = Color(hex: 0x4ECDC4)
    static let goalMintDark = Color(hex: 0x26A69A)
    static let goalMintLight = Color(hex: 0x7EDDD6)

    // Semantic
    static let incomeGreen = Color(hex: 0x4CAF50)
    static let expenseRed = Color(hex: 0xFF5252)
    static let warningAmber = Color(hex: 0xFFB74D)

    // Goal Colors (for user selection)
    static let goalBlue = Color(hex: 0x42A5F5)
    static let goalPurple = Color(hex: 0xAB47BC)
    static let goalPink = Color(hex: 0xEC407A)
    static let goalOrange = Color(hex: 0xFFA726)
    static let goalTeal = Color(hex: 0x26C6DA)
    static let goalIndigo = Color(hex: 0x5C6BC0)

    // Text
    static let textPrimaryLight = Color.white
    static let textSecondaryLight = Color.white.opacity(0.7)
    static let textTertiaryLight = Color.white.opacity(0.5)

    // Surface (for light mode)
    static let surfaceLight = Color(hex: 0xF5F7FA)
    static let cardLight = Color.white

    // All goal color options
    static let goalColorOptions: [Color] = [
        .goalMint, .goalBlue, .goalPurple, .goalPink,
        .goalOrange, .goalTeal, .goalIndigo, .incomeGreen
    ]

    // Goal color hex strings for Core Data storage
    static let goalColorHexOptions: [String] = [
        "4ECDC4", "42A5F5", "AB47BC", "EC407A",
        "FFA726", "26C6DA", "5C6BC0", "4CAF50"
    ]
}

// MARK: - Gradient Presets

extension LinearGradient {
    /// Primary mint gradient for buttons and accents
    static let mintGradient = LinearGradient(
        colors: [Color.goalMint, Color.goalMintDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Navy background gradient
    static let navyGradient = LinearGradient(
        colors: [Color.navyPrimary, Color.navySecondary],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Card background gradient
    static let cardGradient = LinearGradient(
        colors: [Color.navyCard, Color.navySecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
