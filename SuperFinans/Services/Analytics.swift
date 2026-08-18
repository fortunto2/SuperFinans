//
//  Analytics.swift
//  SuperFinans
//
//  The first Swift client for superduper-analytics (the web snippet is served
//  by the Worker; mobile had nothing until now). Speaks the same contract as
//  src/schema.ts: POST /e with {events:[…]}.
//
//  What it never sends: an amount, a date, a currency total, anything derived
//  from what the person typed. The app promises the numbers stay on the phone
//  and that promise has to survive contact with analytics — so this reports
//  that a thing happened, never what it was.
//

import Foundation
import UIKit

@MainActor
final class Analytics {

    static let shared = Analytics()

    private static let endpoint = URL(string: "https://analytics.superduperai.co/e")!
    private static let source = "superfinans"
    private static let anonKey = "superfinans.anon_id"
    /// Opt-out lives next to the data it governs, and defaults to on.
    static let enabledKey = "superfinans.analytics_enabled"

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.waitsForConnectivity = false
        return URLSession(configuration: config)
    }()

    private var queue: [[String: Any]] = []

    private init() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { _ in Task { @MainActor in Analytics.shared.flush() } }
    }

    // MARK: - Identity

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool ?? true
    }

    /// Install-scoped, not device-scoped: reinstalling makes a new person, which
    /// is the trade the schema asks for in exchange for no consent banner.
    private var anonID: String {
        if let existing = UserDefaults.standard.string(forKey: Self.anonKey) { return existing }
        let fresh = UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: Self.anonKey)
        return fresh
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    // MARK: - Recording

    /// `props` must stay categorical — a currency code is fine, a balance is not.
    func track(_ name: String, screen: String? = nil, props: [String: String] = [:]) {
        guard isEnabled else { return }
        var event: [String: Any] = [
            "source": Self.source,
            "platform": "ios",
            "name": name,
            "anon": anonID,
            "ts": Int(Date().timeIntervalSince1970 * 1000),
            "version": appVersion,
        ]
        if let screen { event["path"] = screen }
        if !props.isEmpty { event["props"] = props }
        queue.append(event)
        if queue.count >= 10 { flush() }
    }

    /// Fire-and-forget: analytics must never be the reason anything visible waits.
    func flush() {
        guard isEnabled, !queue.isEmpty else { return }
        let batch = queue
        queue.removeAll()
        guard let body = try? JSONSerialization.data(withJSONObject: ["events": batch]) else { return }

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        session.dataTask(with: request).resume()
    }

    /// Called when the person turns it off — the queue should not outlive consent.
    func discardPending() {
        queue.removeAll()
    }
}
