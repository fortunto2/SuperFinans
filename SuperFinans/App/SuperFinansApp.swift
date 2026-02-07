//
//  SuperFinansApp.swift
//  SuperFinans
//
//  Main entry point. Configures SuperDuperAiAuth, manages onboarding gate,
//  handles deep links, and scene phase lifecycle.
//

import SwiftUI
import SuperDuperAiAuth

@main
struct SuperFinansApp: App {

    // MARK: - App Delegate

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Environment

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Onboarding

    @AppStorage("superfinans.onboarding_completed") private var hasCompletedOnboarding = false

    // MARK: - State

    @State private var deepLinkGoalId: UUID?

    // MARK: - Init

    init() {
        SuperDuperAiAuth.configure(
            appId: "superfinans",
            iosClientId: "YOUR_IOS_CLIENT_ID.apps.googleusercontent.com",
            products: [ProductConfig(id: "superfinans.premium.lifetime", tier: .lifetime)]
        )

        // Ensure a default account exists
        Task { @MainActor in
            AccountService.shared.ensureDefaultAccount()
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .environment(\.managedObjectContext, PersistenceController.shared.viewContext)
                    .tint(.goalMint)
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
            } else {
                OnboardingView(isCompleted: $hasCompletedOnboarding)
            }
        }
        .onChange(of: scenePhase) { newPhase in
            handleScenePhase(newPhase)
        }
    }

    // MARK: - Deep Links

    /// Handle URLs: superfinans://goal/{id}, superfinans://add-transaction
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "superfinans" else { return }

        switch url.host {
        case "goal":
            if let idString = url.pathComponents.dropFirst().first,
               let id = UUID(uuidString: idString) {
                deepLinkGoalId = id
            }
        case "add-transaction":
            // Post notification for tab switch + sheet presentation
            NotificationCenter.default.post(name: .openAddTransaction, object: nil)
        default:
            break
        }
    }

    // MARK: - Scene Phase

    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            PremiumManager.shared.refreshStatus()
        case .background:
            PersistenceController.shared.save()
        case .inactive:
            break
        @unknown default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openAddTransaction = Notification.Name("openAddTransaction")
}
