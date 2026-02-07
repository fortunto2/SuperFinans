//
//  Decimal+Financial.swift
//  SuperFinans
//
//  Decimal math extensions for financial calculations.
//

import Foundation

extension Decimal {
    /// Raise Decimal to an integer power using NSDecimalNumber
    func power(_ exponent: Int) -> Decimal {
        NSDecimalNumber(decimal: self).raising(toPower: exponent) as Decimal
    }

    /// Convert to Double (lossy, for chart display only)
    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    /// Round to specified decimal places
    func rounded(scale: Int = 2, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var result = Decimal()
        var mutableSelf = self
        NSDecimalRound(&result, &mutableSelf, scale, mode)
        return result
    }

    /// Percentage representation (0.25 -> "25%")
    var percentFormatted: String {
        let percentage = (self * 100).rounded(scale: 1)
        return "\(percentage)%"
    }
}
