//
//  SettingsView.swift
//  SuperFinans
//
//  App settings with account, purchase, currency, data, and appearance sections.
//

import SwiftUI
import SuperDuperAnalytics
import SuperDuperAiAuth

struct SettingsView: View {

    @AppStorage("com.superduperai.analytics.enabled") private var analyticsEnabled = true

    @AppStorage("superfinans.currency_code") private var currencyCode = "USD"
    @AppStorage("superfinans.appearance") private var appearance = "system"
    @State private var showPaywall = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            List {
                // Account (SuperDuperAiAuth)
                Section("Account") {
                    if SuperDuperAiAuth.shared.authState.isAuthenticated {
                        AuthSettingsSection(
                            subscriptionTier: SuperDuperAiAuth.shared.subscription.tier,
                            onManageSubscription: { showPaywall = true },
                            onSignOut: {
                                Task { await SuperDuperAiAuth.shared.signOut() }
                            },
                            onDeleteAccount: {
                                Task { try? await SuperDuperAiAuth.shared.deleteAccount() }
                            }
                        )
                    } else {
                        Button {
                            Task { try? await SuperDuperAiAuth.shared.signInWithApple() }
                        } label: {
                            Label("Sign In with Apple", systemImage: "apple.logo")
                        }

                        Button {
                            Task { try? await SuperDuperAiAuth.shared.signInWithGoogle() }
                        } label: {
                            Label("Sign In with Google", systemImage: "globe")
                        }

                        Text("Sign in is optional. Your data is stored on-device and syncs via iCloud.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Purchase
                Section("Premium") {
                    if PremiumManager.shared.isPremium {
                        Label("Premium Active", systemImage: "crown.fill")
                            .foregroundColor(.goalMint)
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Label("Upgrade to Premium", systemImage: "crown.fill")
                                Spacer()
                                Text("$29.99")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Currency
                Section("Currency") {
                    Picker("Default Currency", selection: $currencyCode) {
                        Text("USD — US Dollar").tag("USD")
                        Text("EUR — Euro").tag("EUR")
                        Text("GBP — British Pound").tag("GBP")
                        Text("CAD — Canadian Dollar").tag("CAD")
                        Text("AUD — Australian Dollar").tag("AUD")
                        Text("JPY — Japanese Yen").tag("JPY")
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
                    Link("Privacy Policy", destination: URL(string: "https://superfinans.app/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://superfinans.app/terms")!)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                SuperFinansPaywallView()
            }
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
