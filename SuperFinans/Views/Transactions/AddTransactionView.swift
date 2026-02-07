//
//  AddTransactionView.swift
//  SuperFinans
//
//  Sheet for adding a new transaction. Numpad-first design.
//

import SwiftUI

struct AddTransactionView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddTransactionViewModel()
    @State private var showCategoryPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Type toggle
                Picker("Type", selection: $viewModel.isExpense) {
                    Text("Expense").tag(true)
                    Text("Income").tag(false)
                }
                .pickerStyle(.segmented)
                .padding()

                // Amount display
                VStack(spacing: 4) {
                    Text(viewModel.isExpense ? "Expense" : "Income")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.amountString.isEmpty ? "0.00" : viewModel.amountString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(viewModel.isExpense ? .expenseRed : .incomeGreen)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.vertical, 16)

                // Category & details
                HStack(spacing: 12) {
                    // Category button
                    Button {
                        showCategoryPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: viewModel.selectedCategory.iconName)
                            Text(viewModel.selectedCategory.displayName)
                                .lineLimit(1)
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(viewModel.selectedCategory.color.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    // Date
                    DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                        .labelsHidden()

                    Spacer()

                    // Account picker
                    if viewModel.accounts.count > 1 {
                        Menu {
                            ForEach(viewModel.accounts, id: \.id) { account in
                                Button(account.displayName) {
                                    viewModel.selectedAccount = account
                                }
                            }
                        } label: {
                            Text(viewModel.selectedAccount?.displayName ?? "Account")
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)

                // Note field
                TextField("Note (optional)", text: $viewModel.note)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                Spacer()

                // Numpad
                NumpadView(
                    onDigit: { viewModel.appendDigit($0) },
                    onDelete: { viewModel.deleteLastDigit() },
                    onClear: { viewModel.clearAmount() }
                )
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Save button
                Button {
                    viewModel.save()
                    dismiss()
                } label: {
                    Text("Save Transaction")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.isValid ? LinearGradient.mintGradient : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!viewModel.isValid)
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCategoryPicker) {
                CategoryPickerView(selectedCategory: $viewModel.selectedCategory)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

#Preview {
    AddTransactionView()
}
