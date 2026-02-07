//
//  GoalsListView.swift
//  SuperFinans
//
//  Main view for the Goals tab showing all financial goals.
//

import SwiftUI

struct GoalsListView: View {

    @StateObject private var viewModel = GoalsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.goals.isEmpty {
                    EmptyStateView(
                        icon: "star.fill",
                        title: "No Goals Yet",
                        subtitle: "Create your first savings goal and start tracking your progress toward financial freedom.",
                        buttonTitle: "Create Goal"
                    ) {
                        viewModel.requestCreateGoal()
                    }
                } else {
                    goalsList
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.requestCreateGoal()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showCreateGoal) {
                viewModel.loadGoals()
            } content: {
                CreateGoalView()
            }
            .sheet(isPresented: $viewModel.showPaywall) {
                SuperFinansPaywallView()
            }
            .overlay {
                if let milestone = viewModel.celebratingMilestone {
                    MilestoneCelebrationView(
                        milestone: milestone,
                        goalName: viewModel.celebratingGoalName ?? "Goal"
                    ) {
                        viewModel.dismissMilestone()
                    }
                }
            }
        }
    }

    // MARK: - Goals List

    private var goalsList: some View {
        List {
            ForEach(viewModel.goals, id: \.id) { goal in
                NavigationLink(destination: GoalDetailView(goal: goal)) {
                    GoalCardView(goal: goal)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            .onDelete(perform: viewModel.deleteGoal)
            .onMove(perform: viewModel.reorderGoals)
        }
        .listStyle(.plain)
    }
}

// MARK: - Milestone Celebration

struct MilestoneCelebrationView: View {
    let milestone: GoalMilestone
    let goalName: String
    let onDismiss: () -> Void

    @State private var showContent = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }

            VStack(spacing: 16) {
                Text(milestone.emoji)
                    .font(.system(size: 72))
                    .scaleEffect(showContent ? 1.0 : 0.3)

                Text("Milestone Reached!")
                    .font(.title2.bold())

                Text("\(goalName) hit \(milestone.label)")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Button("Continue", action: onDismiss)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(LinearGradient.mintGradient)
                    .clipShape(Capsule())
                    .padding(.top, 8)
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(40)
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }
        }
    }
}

#Preview {
    GoalsListView()
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
