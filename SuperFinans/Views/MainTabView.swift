//
//  MainTabView.swift
//  SuperFinans
//
//  4-tab navigation: Goals, Transactions, Insights, Settings.
//

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Tab = .goals
    @Binding var deepLinkGoalId: UUID?

    enum Tab: String, CaseIterable {
        case goals
        case transactions
        case insights
        case settings

        var title: String {
            switch self {
            case .goals: return "Goals"
            case .transactions: return "Transactions"
            case .insights: return "Insights"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .goals: return "star.fill"
            case .transactions: return "list.bullet.rectangle.portrait"
            case .insights: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GoalsListView(deepLinkGoalId: $deepLinkGoalId)
                .tabItem {
                    Label(Tab.goals.title, systemImage: Tab.goals.icon)
                }
                .tag(Tab.goals)

            TransactionsListView()
                .tabItem {
                    Label(Tab.transactions.title, systemImage: Tab.transactions.icon)
                }
                .tag(Tab.transactions)

            InsightsDashboardView()
                .tabItem {
                    Label(Tab.insights.title, systemImage: Tab.insights.icon)
                }
                .tag(Tab.insights)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(.goalMint)
        .onChange(of: deepLinkGoalId) { _ in
            if deepLinkGoalId != nil {
                selectedTab = .goals
            }
        }
    }
}

#Preview {
    MainTabView(deepLinkGoalId: .constant(nil))
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
