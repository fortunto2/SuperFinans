//
//  MoneyTextField.swift
//  SuperFinans
//
//  TextField configured for monetary input.
//

import SwiftUI

struct MoneyTextField: View {

    let label: String
    @Binding var value: String
    var currencyCode: String = "USD"

    var body: some View {
        HStack {
            Text(currencySymbol)
                .font(.title2.bold())
                .foregroundStyle(.secondary)

            TextField(label, text: $value)
                .font(.title2.bold())
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var currencySymbol: String {
        let locale = Locale.current
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.currencySymbol ?? "$"
    }
}

#Preview {
    MoneyTextField(label: "Amount", value: .constant("150.00"))
        .padding()
}
