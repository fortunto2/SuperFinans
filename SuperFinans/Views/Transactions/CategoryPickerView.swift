//
//  CategoryPickerView.swift
//  SuperFinans
//
//  Grid picker for transaction categories.
//

import SwiftUI

struct CategoryPickerView: View {

    @Binding var selectedCategory: CategoryDefinition
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(CategoryDefinition.allCases) { category in
                        Button {
                            selectedCategory = category
                            dismiss()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: category.iconName)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .background(
                                        category == selectedCategory
                                            ? category.color.opacity(0.2)
                                            : Color(.secondarySystemGroupedBackground)
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(category == selectedCategory ? category.color : .clear, lineWidth: 2)
                                    )

                                Text(category.displayName)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(category == selectedCategory ? category.color : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    CategoryPickerView(selectedCategory: .constant(.groceries))
}
