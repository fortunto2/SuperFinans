//
//  MainTabView.swift
//  SuperFinans
//
//  5-tab navigation: Goals, Transactions, Insights, Guide, Settings.
//

import SwiftUI

struct MainTabView: View {

    @State private var selectedTab: Tab = .goals

    enum Tab: String, CaseIterable {
        case goals
        case transactions
        case insights
        case guide
        case settings

        var title: String {
            switch self {
            case .goals: return "Goals"
            case .transactions: return "Transactions"
            case .insights: return "Insights"
            case .guide: return "Guide"
            case .settings: return "Settings"
            }
        }

        var icon: String {
            switch self {
            case .goals: return "star.fill"
            case .transactions: return "list.bullet.rectangle.portrait"
            case .insights: return "chart.bar.fill"
            case .guide: return "book.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GoalsListView()
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

            NavigationStack {
                GuideView()
            }
            .tabItem {
                Label(Tab.guide.title, systemImage: Tab.guide.icon)
            }
            .tag(Tab.guide)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.title, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(.goalMint)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
