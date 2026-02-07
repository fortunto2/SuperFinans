//
//  NumpadView.swift
//  SuperFinans
//
//  Custom numpad for quick amount entry.
//

import SwiftUI

struct NumpadView: View {

    let onDigit: (String) -> Void
    let onDelete: () -> Void
    let onClear: () -> Void

    private let buttons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]

    var body: some View {
        VStack(spacing: 8) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { button in
                        Button {
                            handleTap(button)
                        } label: {
                            Text(button)
                                .font(.title2.bold())
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func handleTap(_ button: String) {
        switch button {
        case "⌫":
            onDelete()
        default:
            onDigit(button)
        }
    }
}
