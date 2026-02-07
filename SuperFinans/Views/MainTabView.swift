//
//  MainTabView.swift
//  SuperFinans
//
//  4-tab navigation: Dashboard, Cash Flow, Balance Sheet, Settings.
//

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Tab = .dashboard
    @Binding var deepLinkGoalId: UUID?

    enum Tab: String, CaseIterable {
        case dashboard
        case cashFlow
        case balance
        case settings

        var title: String {
            switch self {
            case .dashboard: return "Dashboard"
            case .cashFlow: return "Cash Flow"
            case .balance: return "Balance"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .dashboard: return "flame.fill"
            case .cashFlow: return "arrow.left.arrow.right"
            case .balance: return "scale.3d"
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

            CashFlowView()
                .tabItem {
                    Label(Tab.cashFlow.title, systemImage: Tab.cashFlow.icon)
                }
                .tag(Tab.cashFlow)

            BalanceSheetView()
                .tabItem {
                    Label(Tab.balance.title, systemImage: Tab.balance.icon)
                }
                .tag(Tab.balance)

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
