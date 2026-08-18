//
//  CurrencyPickerView.swift
//  SuperFinans
//
//  Which currency the person thinks in. Asked once, before the three numbers,
//  because "1200" means nothing until we know what it is.
//
//  The list comes from Foundation, not from a hand-kept enum: ~150 ISO codes
//  with names already localised into the user's language, updated with iOS.
//

import SwiftUI

struct CurrencyPickerView: View {

    @Binding var selection: String
    /// Called on pick, so onboarding can move on without a second tap.
    var onPick: ((String) -> Void)?

    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    /// The handful worth putting above the fold. The rest is one search away.
    private static let popular = ["USD", "EUR", "GBP", "TRY", "RUB", "CHF", "AED", "KZT"]

    /// Codes Foundation still lists but no rate feed quotes: CUC was abolished in
    /// 2021, VEF was redenominated into VES, KPW is not traded. Offering them
    /// would mean a plan whose second currency silently never resolves.
    private static let unquoted: Set<String> = ["CUC", "KPW", "VEF"]

    private var all: [String] {
        Locale.commonISOCurrencyCodes.filter { !Self.unquoted.contains($0) }
    }

    /// Localised names, resolved once. Filtering used to call into ICU for
    /// every one of ~150 codes on every character typed.
    private static let names: [String: String] = {
        var map: [String: String] = [:]
        for code in Locale.commonISOCurrencyCodes {
            map[code] = Locale.current.localizedString(forCurrencyCode: code) ?? code
        }
        return map
    }()

    private var filtered: [String] {
        guard !query.isEmpty else { return all }
        let q = query.lowercased()
        return all.filter {
            $0.lowercased().contains(q) || (Self.names[$0] ?? $0).lowercased().contains(q)
        }
    }

    var body: some View {
        List {
            if query.isEmpty {
                Section("Common") {
                    ForEach(Self.popular, id: \.self) { row($0) }
                }
            }
            Section(query.isEmpty ? "All currencies" : "Results") {
                ForEach(filtered, id: \.self) { row($0) }
            }
        }
        .searchable(text: $query, prompt: "Currency or code")
    }

    private func row(_ code: String) -> some View {
        Button {
            selection = code
            onPick?(code)
            // Picking is the whole purpose of this screen; staying on it after
            // the pick makes the person hunt for a back button.
            dismiss()
        } label: {
            HStack {
                Text(Self.symbol(for: code))
                    .font(.headline)
                    .frame(width: 44, alignment: .leading)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 1) {
                    Text(code).font(.body)
                    Text(Self.name(for: code))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if code == selection {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.goalMintDark)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Naming

    static func name(for code: String) -> String {
        names[code] ?? Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    /// Falls back to the code — plenty of currencies have no distinct glyph.
    static func symbol(for code: String) -> String {
        let symbol = String.currencySymbol(for: code)
        return symbol.count <= 3 ? symbol : code
    }
}

// MARK: - Onboarding step

/// The first thing asked, and the only question with an obvious default —
/// the device locale is usually right, so it is preselected and one tap moves on.
struct CurrencyStepView: View {

    @ObservedObject var store: FreedomPlanStore
    var onDone: () -> Void

    @State private var picked: String = ""

    var body: some View {
        NavigationStack {
            CurrencyPickerView(selection: $picked) { code in
                store.setCurrency(code)
                onDone()
            }
            .navigationTitle("Your currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") { onDone() }
                }
            }
            .onAppear { picked = store.plan.currencyCode }
        }
    }
}
