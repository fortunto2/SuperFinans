//
//  Money.swift
//  SuperFinans
//
//  Value type for monetary amounts using Int64 minor units.
//  Avoids floating-point precision issues.
//

import Foundation

struct Money: Equatable, Hashable, Codable, Sendable {

    // MARK: - Properties

    /// Amount in minor units (e.g., 12345 = $123.45)
    let minorUnits: Int64

    /// ISO 4217 currency code (e.g., "USD", "GBP")
    let currencyCode: String

    // MARK: - Init

    init(minorUnits: Int64, currencyCode: String) {
        self.minorUnits = minorUnits
        self.currencyCode = currencyCode
    }

    /// Init from a major-unit decimal (e.g., 123.45)
    init(amount: Decimal, currencyCode: String) {
        let scale = Money.minorUnitScale(for: currencyCode)
        let scaled = amount * Decimal(scale)
        self.minorUnits = NSDecimalNumber(decimal: scaled).int64Value
        self.currencyCode = currencyCode
    }

    // MARK: - Computed

    /// The amount as a Decimal in major units
    var decimalAmount: Decimal {
        let scale = Money.minorUnitScale(for: currencyCode)
        return Decimal(minorUnits) / Decimal(scale)
    }

    /// Formatted string using the system locale (e.g., "$123.45")
    var formatted: String {
        let decimal = decimalAmount
        return decimal.formatted(.currency(code: currencyCode))
    }

    /// Short formatted without currency symbol for display in charts
    var shortFormatted: String {
        let decimal = decimalAmount
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSDecimalNumber(decimal: decimal)) ?? "\(decimal)"
    }

    /// Whether this is zero
    var isZero: Bool { minorUnits == 0 }

    /// Whether this is positive
    var isPositive: Bool { minorUnits > 0 }

    /// Whether this is negative
    var isNegative: Bool { minorUnits < 0 }

    // MARK: - Arithmetic

    static func + (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currencyCode == rhs.currencyCode, "Cannot add different currencies")
        return Money(minorUnits: lhs.minorUnits + rhs.minorUnits, currencyCode: lhs.currencyCode)
    }

    static func - (lhs: Money, rhs: Money) -> Money {
        precondition(lhs.currencyCode == rhs.currencyCode, "Cannot subtract different currencies")
        return Money(minorUnits: lhs.minorUnits - rhs.minorUnits, currencyCode: lhs.currencyCode)
    }

    static prefix func - (money: Money) -> Money {
        Money(minorUnits: -money.minorUnits, currencyCode: money.currencyCode)
    }

    // MARK: - Comparable

    static func < (lhs: Money, rhs: Money) -> Bool {
        precondition(lhs.currencyCode == rhs.currencyCode, "Cannot compare different currencies")
        return lhs.minorUnits < rhs.minorUnits
    }

    // MARK: - Zero

    static func zero(currencyCode: String = "USD") -> Money {
        Money(minorUnits: 0, currencyCode: currencyCode)
    }

    // MARK: - Private Helpers

    /// Returns the minor unit scale (e.g., 100 for USD, 1 for JPY)
    private static func minorUnitScale(for currencyCode: String) -> Int {
        switch currencyCode {
        case "JPY", "KRW", "VND":
            return 1
        case "BHD", "KWD", "OMR":
            return 1000
        default:
            return 100
        }
    }
}
