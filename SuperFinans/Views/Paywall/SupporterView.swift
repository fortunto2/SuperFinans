//
//  SupporterView.swift
//  SuperFinans
//
//  Not a paywall — nothing is behind it. It asks, once, and takes no for an
//  answer, which is the only version of this screen that does not make people
//  resent an app they otherwise like.
//

import SwiftUI

struct SupporterView: View {

    @ObservedObject var store: SupporterStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    VStack(alignment: .leading, spacing: 14) {
                        perk("tablecells", "CSV export",
                             "Your accounts and transactions as a spreadsheet, not just JSON")
                        perk("heart.text.square", "A line in Settings that says you paid for this",
                             "Which is, honestly, most of what you are buying")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    buyButton

                    Text("One payment. No subscription, no renewal, nothing expires. Everything that answers the question — the year, the slider, life events, the widget — is free and stays free whether you buy this or not.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Restore purchase") {
                        Task { await store.restore() }
                    }
                    .font(.footnote)
                }
                .padding(24)
            }
            .navigationTitle("Support the app")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
            }
            .task { await store.load() }
            .onChange(of: store.isSupporter) { supporter in
                if supporter { dismiss() }
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 44))
                .foregroundStyle(Color.goalMintDark)
            Text("Built by one person")
                .font(.title2.bold())
            Text("No ads, no data sold, no investor deciding what this app becomes. If it told you something useful, this is how it keeps going.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private func perk(_ icon: String, _ title: String, _ detail: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 26)
                .foregroundStyle(Color.goalMintDark)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.medium))
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var buyButton: some View {
        Button {
            Task { await store.purchase() }
        } label: {
            Group {
                if store.isPurchasing {
                    ProgressView().tint(.white)
                } else if store.displayPrice.isEmpty {
                    Text("Support the app")
                } else {
                    Text("Support the app · \(store.displayPrice)")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.goalMintDark)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(store.isPurchasing || store.product == nil)
    }
}

// MARK: - Settings row

/// Thanks where it belongs, and the ask where it does not interrupt anything.
struct SupporterSettingsRow: View {

    @ObservedObject var store: SupporterStore
    @State private var showSheet = false

    var body: some View {
        if store.isSupporter {
            HStack {
                Label("Supporter", systemImage: "heart.fill")
                    .foregroundStyle(Color.goalMintDark)
                Spacer()
                Text("Thank you")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Button {
                showSheet = true
            } label: {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Support the app")
                            Text("One payment, no subscription")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "heart")
                            .foregroundStyle(Color.goalMintDark)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.automatic)
            .sheet(isPresented: $showSheet) {
                SupporterView(store: store)
            }
        }
    }
}
