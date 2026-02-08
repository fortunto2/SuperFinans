//
//  MainTabView.swift
//  SuperFinans
//
//  4-tab navigation: Dashboard, Transactions, Wealth, Settings.
//

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Tab = .dashboard
    @Binding var deepLinkGoalId: UUID?

    enum Tab: String, CaseIterable {
        case dashboard
        case transactions
        case wealth
        case settings

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .transactions: return "Transactions"
            case .wealth: return "Wealth"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "flame.fill"
            case .transactions: return "list.bullet.rectangle.portrait"
            case .wealth: return "chart.line.uptrend.xyaxis"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(deepLinkGoalId: $deepLinkGoalId)
                .tabItem {
                    Label(Tab.dashboard.title, systemImage: Tab.dashboard.icon)
                }
                .tag(Tab.dashboard)

            TransactionsListView()
                .tabItem {
                    Label(Tab.transactions.title, systemImage: Tab.transactions.icon)
                }
                .tag(Tab.transactions)

            BalanceSheetView()
                .tabItem {
                    Label(Tab.wealth.title, systemImage: Tab.wealth.icon)
                }
                .tag(Tab.wealth)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(.goalMint)
        .onChange(of: deepLinkGoalId) { _ in
            if deepLinkGoalId != nil {
                selectedTab = .dashboard
            }
        }
    }
}

#Preview {
    MainTabView(deepLinkGoalId: .constant(nil))
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
