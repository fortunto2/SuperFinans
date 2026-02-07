//
//  FreedomProjection.swift
//  SuperFinans
//
//  Data point for freedom projection charts (passive income vs expenses).
//

import Foundation

/// A single point on the freedom projection curve
struct FreedomProjectionPoint: Identifiable, Sendable {
    let id = UUID()
    let month: Int
    let date: Date
    let passiveIncome: Decimal
    let totalInvestedAssets: Decimal
    let expenses: Decimal
    let freedomRatio: Decimal
}
