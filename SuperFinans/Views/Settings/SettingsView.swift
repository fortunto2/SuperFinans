//
//  SettingsView.swift
//  SuperFinans
//
//  App settings with account, purchase, currency, data, and appearance sections.
//

import SwiftUI
import SuperDuperAnalytics

struct SettingsView: View {

    @AppStorage("com.superduperai.analytics.enabled") private var analyticsEnabled = true
    @StateObject private var supporterStore = SupporterStore.shared

    @AppStorage("superfinans.currency_code") private var currencyCode = "USD"
    @AppStorage("superfinans.appearance") private var appearance = "system"
    @State private var showExportSheet = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            List {
                // No sign-in. Nothing here needs an account: the data is local,
                // iCloud syncs it under the person's own Apple ID, and the
                // purchase rides their App Store account. An account we do not
                // need is a login screen to maintain, a deletion flow to honour
                // and a row of personal data to declare.
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Synced through your iCloud")
                            Text("No account, no password. Your data follows your Apple ID and stays yours.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "icloud")
                            .foregroundStyle(Color.goalMintDark)
                    }
                } header: {
                    Text("Your data")
                }

                // Purchase
                // Not "Premium" — nothing is locked. The price comes from
                // StoreKit so it is right in every storefront, rather than a
                // hardcoded $29.99 that is wrong everywhere outside the US.
                Section {
                    SupporterSettingsRow(store: supporterStore)
                }

                // Currency
                Section("Currency") {
                    NavigationLink {
                        CurrencyPickerView(selection: $currencyCode) { code in
                            FreedomPlanStore.shared.setCurrency(code)
                        }
                        .navigationTitle("Currency")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            Text("Default Currency")
                            Spacer()
                            Text("\(currencyCode) — \(CurrencyPickerView.name(for: currencyCode))")
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }

                // Data
                Section("Data") {
                    Button {
                        exportURL = ExportService.shared.exportFileURL()
                        if exportURL != nil {
                            showExportSheet = true
                        }
                    } label: {
                        Label("Export Data (JSON)", systemImage: "square.and.arrow.up")
                    }

                    if supporterStore.isSupporter {
                        Button {
                            exportURL = ExportService.shared.exportCSVFileURL()
                            if exportURL != nil { showExportSheet = true }
                        } label: {
                            Label("Export Transactions (CSV)", systemImage: "tablecells")
                        }
                    }
                }

                // Appearance
                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                }

                // Guide
                Section("Help") {
                    NavigationLink {
                        GuideView()
                    } label: {
                        Label("Guide", systemImage: "book.fill")
                    }
                }

                // Stated plainly and switchable, because the onboarding screen
                // makes a privacy promise and a silent counter would break it.
                Section {
                    Toggle(isOn: $analyticsEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Anonymous usage stats")
                            Text("How often the app is opened, and which features get used. No profile, no advertising, no third party — and never an amount.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onChange(of: analyticsEnabled) { enabled in
                        Analytics.isEnabled = enabled
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("A count, not a trail: there is no cookie, no device fingerprint and nothing that ties one launch to another person.")
                }

                // Cross-promotion. Only apps that share this one's premise —
                // multi-currency, privacy-first, no subscription — and only
                // apps that are actually live on the Store.
                Section("More from us") {
                    Link(destination: URL(string: "https://apps.apple.com/app/id6759005730")!) {
                        HStack {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .foregroundStyle(Color.goalMintDark)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("CurrencyPals")
                                Text("Offline currency converter — the rates behind this app")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            // Without this the row reads as a label, not a link out.
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                    Link("Privacy Policy", destination: URL(string: "https://fortunto2.github.io/SuperFinans/privacy/")!)
                    Link("Support", destination: URL(string: "https://fortunto2.github.io/SuperFinans/support/")!)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
}
