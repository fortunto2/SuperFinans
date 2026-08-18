//
//  RateService.swift
//  SuperFinans
//
//  Fiat rates, lifted from CurrencyPal's ExchangeRateService and cut down to
//  what a freedom calculator needs: one USD-based snapshot, cached, with the
//  cache surviving a failed refresh.
//
//  Two sources because one is not enough: Frankfurter covers the ECB set and
//  omits RUB, TRY and most soft currencies, which is exactly the audience that
//  needs a second currency on screen.
//

import Foundation

struct RateSnapshot: Codable, Sendable {
    /// "1 USD = rates[code]" — always USD-based, so any pair is two lookups.
    /// Includes XAU: grams of gold per dollar, so gold behaves like any other
    /// unit a person keeps savings in.
    let rates: [String: Double]
    let fetchedAt: Date

    func convert(_ amount: Double, from: String, to: String) -> Double? {
        guard from != to else { return amount }
        let fromRate = from == "USD" ? 1.0 : rates[from]
        let toRate = to == "USD" ? 1.0 : rates[to]
        guard let f = fromRate, let t = toRate, f > 0 else { return nil }
        return amount / f * t
    }

    var isStale: Bool {
        Date().timeIntervalSince(fetchedAt) > 24 * 3600
    }
}

actor RateService {

    static let shared = RateService()

    private static let cacheKey = "superfinans.rate_snapshot"

    /// A converter that hangs for the default 60s reads as broken.
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 20
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    // MARK: - Cache

    /// Last known rates. Offline is the normal case for an offline-first app,
    /// so a stale snapshot beats no snapshot — the UI labels the date.
    nonisolated static func cached() -> RateSnapshot? {
        guard let data = FreedomPlanStorage.defaults.data(forKey: cacheKey),
              let snapshot = try? JSONDecoder().decode(RateSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }

    private func store(_ snapshot: RateSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        FreedomPlanStorage.defaults.set(data, forKey: Self.cacheKey)
    }

    // MARK: - Fetch

    /// Refresh if the cache is missing or older than a day. Never throws: a
    /// failed refresh must leave the previous snapshot intact.
    @discardableResult
    func refreshIfNeeded() async -> RateSnapshot? {
        if let cached = Self.cached(), !cached.isStale { return cached }
        do {
            let snapshot = try await fetchUSDSnapshot()
            store(snapshot)
            return snapshot
        } catch {
            return Self.cached()
        }
    }

    private func fetchUSDSnapshot() async throws -> RateSnapshot {
        async let ecbTask = fetch(url: URL(string: "https://api.frankfurter.dev/v1/latest?base=USD")!,
                                  decode: FrankfurterPayload.self)
        async let openTask = fetch(url: URL(string: "https://open.er-api.com/v6/latest/USD")!,
                                   decode: OpenERPayload.self)
        async let goldTask = fetch(
            url: URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=pax-gold&vs_currencies=usd")!,
            decode: CoinGeckoPayload.self)

        // Frankfurter is the trusted set; open.er-api fills the gaps (RUB, TRY…);
        // gold is best-effort — losing it must not cost anyone their currencies.
        let supplementary = try? await openTask
        let gold = try? await goldTask
        let ecb = try? await ecbTask

        var rates: [String: Double] = [:]
        for (code, rate) in supplementary?.rates ?? [:] where rate > 0 { rates[code] = rate }
        for (code, rate) in ecb?.rates ?? [:] where rate > 0 { rates[code] = rate }

        // PAXG is one troy ounce of allocated gold and tracks spot within a
        // fraction of a percent — close enough for a plan measured in decades,
        // and it needs no API key, unlike every metals feed.
        if let ounce = gold?.paxGold.usd, ounce > 0 {
            rates[Metal.goldCode] = Metal.gramsPerTroyOunce / ounce
        }

        guard !rates.isEmpty else { throw RateError.unavailable }
        rates["USD"] = 1
        return RateSnapshot(rates: rates, fetchedAt: Date())
    }

    private func fetch<T: Decodable>(url: URL, decode: T.Type) async throws -> T {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw RateError.unavailable
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    enum RateError: Error { case unavailable }
}

// MARK: - Payloads

private struct FrankfurterPayload: Decodable {
    let rates: [String: Double]
}

private struct OpenERPayload: Decodable {
    let rates: [String: Double]
}

private struct CoinGeckoPayload: Decodable {
    struct Quote: Decodable { let usd: Double }
    let paxGold: Quote

    enum CodingKeys: String, CodingKey { case paxGold = "pax-gold" }
}

/// Gold is quoted per gram because that is how it is bought and kept in Turkey,
/// India and the Gulf — nobody there thinks in troy ounces.
enum Metal {
    static let goldCode = "XAU"
    static let gramsPerTroyOunce = 31.1034768

    static func isMetal(_ code: String) -> Bool { code == goldCode }

    /// "12 g" rather than a currency symbol, since a gram is not a currency.
    static func format(grams: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        let value = formatter.string(from: NSNumber(value: grams)) ?? "\(grams)"
        return "\(value) g"
    }
}

// MARK: - Currency character

enum CurrencyClass {

    /// Currencies whose long-run return assumptions match the ~7% figure the
    /// planner uses. Everything else carries an inflation premium that makes a
    /// nominal 7% meaningless over a 20-year horizon.
    static let hard: Set<String> = [
        "USD", "EUR", "GBP", "CHF", "JPY", "CAD", "AUD", "NZD", "SEK", "NOK", "DKK", "SGD"
    ]

    static func isHard(_ code: String) -> Bool { hard.contains(code.uppercased()) }
}


// MARK: - Plan in another currency

/// Lives here, not on the model: the widget links FreedomPlan on its own
/// and has no business carrying a networking type.
extension FreedomPlan {

    /// The 7% default is a dollar-market number. In a currency that runs 10%+
    /// inflation it is not conservative, it is wrong — and over 20 years the
    /// error compounds into a decade.
    var returnAssumptionIsCredible: Bool { CurrencyClass.isHard(currencyCode) }

    /// Restate every amount in another currency at the given snapshot.
    func converted(to code: String, using snapshot: RateSnapshot) -> FreedomPlan? {
        func move(_ minor: Int64) -> Int64? {
            let major = Double(minor) / 100
            guard let out = snapshot.convert(major, from: currencyCode, to: code) else { return nil }
            return Int64((out * 100).rounded())
        }
        guard let expenses = move(monthlyExpensesMinor),
              let savings = move(currentSavingsMinor),
              let monthly = move(monthlySavingsMinor)
        else { return nil }

        var copy = self
        copy.monthlyExpensesMinor = expenses
        copy.currentSavingsMinor = savings
        copy.monthlySavingsMinor = monthly
        copy.currencyCode = code
        copy.displayCurrencyCode = CurrencyClass.isHard(code) ? nil : displayCurrencyCode
        return copy
    }

    /// A fresh plan in a soft currency defaults to showing USD alongside.
    static func seeded(currencyCode: String) -> FreedomPlan {
        var plan = FreedomPlan.empty(currencyCode: currencyCode)
        plan.displayCurrencyCode = CurrencyClass.isHard(currencyCode) ? nil : "USD"
        return plan
    }
}


// MARK: - Valuing holdings

extension FreedomPlan {

    /// Value every holding in the plan's currency at the given rates.
    /// Anything whose unit has no quote is skipped rather than counted as zero —
    /// silently deleting someone's savings is worse than showing them unvalued.
    func revaluingHoldings(using snapshot: RateSnapshot) -> FreedomPlan {
        var total = 0.0
        for holding in holdings {
            guard let value = snapshot.convert(holding.amount, from: holding.unit, to: currencyCode)
            else { continue }
            total += value
        }
        var copy = self
        copy.holdingsValueMinor = Int64((total * 100).rounded())
        return copy
    }

    /// Holdings that the current rates cannot price — shown to the person rather
    /// than hidden, so a missing gold quote does not look like missing gold.
    func unvaluedHoldings(using snapshot: RateSnapshot?) -> [Holding] {
        guard let snapshot else { return holdings }
        return holdings.filter {
            snapshot.convert($0.amount, from: $0.unit, to: currencyCode) == nil
        }
    }
}
