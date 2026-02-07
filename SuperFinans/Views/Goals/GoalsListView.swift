//
//  GoalsListView.swift
//  SuperFinans
//
//  Main view for the Goals tab showing all financial goals with
//  summary header, template-based empty state, swipe actions, and hints.
//

import SwiftUI

struct GoalsListView: View {

    @StateObject private var viewModel = GoalsViewModel()
    @Binding var deepLinkGoalId: UUID?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.goals.isEmpty {
                    goalsEmptyState
                } else {
                    goalsList
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        if !viewModel.goals.isEmpty {
                            NavigationLink(destination: GoalProjectionsView(goals: viewModel.goals)) {
                                Image(systemName: "chart.xyaxis.line")
                            }
                        }
                        Button {
                            viewModel.requestCreateGoal()
                        } label: {
                            Image(systemName: "plus")
                        }
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
            .sheet(item: $viewModel.quickDepositGoal) { goal in
                quickDepositSheet(for: goal)
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
            .navigationDestination(for: GoalEntity.self) { goal in
                GoalDetailView(goal: goal)
            }
            .onChange(of: deepLinkGoalId) { newId in
                if let id = newId,
                   let goal = viewModel.goals.first(where: { $0.id == id }) {
                    navigationPath.append(goal)
                    deepLinkGoalId = nil
                }
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.totalSaved.formatted)
                        .font(.title2.bold())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.goals.count) goal\(viewModel.goals.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(viewModel.overallProgress * 100))% overall")
                        .font(.subheadline.bold())
                        .foregroundColor(.goalMint)
                }
            }

            ProgressView(value: viewModel.overallProgress)
                .tint(.goalMint)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Hint Banner (Progressive Disclosure)

    @ViewBuilder
    private var transactionsHint: some View {
        if FeatureDiscoveryFlags.shared.shouldShowTransactionsHint {
            HintBannerView(
                icon: "list.bullet.rectangle.portrait",
                message: "Track your spending in the Transactions tab to see where your money goes.",
                color: .goalBlue
            ) {
                FeatureDiscoveryFlags.shared.hasShownTransactionsHint = true
            }
        }
    }

    // MARK: - Goals List

    private var goalsList: some View {
        List {
            Section {
                summaryHeader
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))

            Section {
                transactionsHint
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

            ForEach(viewModel.goals, id: \.id) { goal in
                NavigationLink(value: goal) {
                    GoalCardView(goal: goal)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .swipeActions(edge: .leading) {
                    Button {
                        viewModel.quickDepositGoal = goal
                        viewModel.quickDepositAmount = ""
                    } label: {
                        Label("Deposit", systemImage: "plus.circle.fill")
                    }
                    .tint(.goalMint)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        if let index = viewModel.goals.firstIndex(where: { $0.id == goal.id }) {
                            viewModel.deleteGoal(at: IndexSet(integer: index))
                        }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
            }
            .onMove(perform: viewModel.reorderGoals)
        }
        .listStyle(.plain)
    }

    // MARK: - Empty State with Templates

    private var goalsEmptyState: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                Image(systemName: "star.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.secondary)
                    .symbolEffect(.pulse)

                VStack(spacing: 8) {
                    Text("No Goals Yet")
                        .font(.title3.bold())
                    Text("Start with a template or create your own goal.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Template buttons
                VStack(spacing: 12) {
                    Text("Quick Start")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)

                    templateButton(
                        name: "Emergency Fund",
                        icon: "shield.fill",
                        color: "4ECDC4",
                        amount: 1_000_000, // $10,000
                        subtitle: "$10,000"
                    )

                    templateButton(
                        name: "Vacation",
                        icon: "airplane",
                        color: "42A5F5",
                        amount: 300_000, // $3,000
                        subtitle: "$3,000"
                    )

                    templateButton(
                        name: "New Car",
                        icon: "car.fill",
                        color: "AB47BC",
                        amount: 2_500_000, // $25,000
                        subtitle: "$25,000"
                    )
                }

                // Custom goal button
                Button {
                    viewModel.requestCreateGoal()
                } label: {
                    Text("Create Custom Goal")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(LinearGradient.mintGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Spacer()
            }
            .padding(.horizontal, 32)
        }
    }

    private func templateButton(name: String, icon: String, color: String, amount: Int64, subtitle: String) -> some View {
        Button {
            viewModel.createFromTemplate(name: name, icon: icon, color: color, amount: amount)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color(hexString: color))
                    .frame(width: 40, height: 40)
                    .background(Color(hexString: color).opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(Color(hexString: color))
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Deposit Sheet

    private func quickDepositSheet(for goal: GoalEntity) -> some View {
        NavigationStack {
            Form {
                MoneyTextField(
                    label: "Amount",
                    value: $viewModel.quickDepositAmount,
                    currencyCode: goal.currency
                )
            }
            .navigationTitle("Deposit to \(goal.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { viewModel.quickDepositGoal = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Deposit") { viewModel.addQuickDeposit() }
                        .bold()
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - GoalEntity Identifiable + Hashable for NavigationPath

extension GoalEntity: @retroactive Identifiable {}

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
    GoalsListView(deepLinkGoalId: .constant(nil))
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
