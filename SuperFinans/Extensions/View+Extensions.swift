//
//  View+Extensions.swift
//  SuperFinans
//
//  SwiftUI view modifier extensions.
//

import SwiftUI

// MARK: - Conditional Modifier

extension View {
    /// Apply a modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Apply different modifiers based on condition
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        ifTrue: (Self) -> TrueContent,
        ifFalse: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTrue(self)
        } else {
            ifFalse(self)
        }
    }
}

// MARK: - Card Style

struct CardModifier: ViewModifier {
    let backgroundColor: Color
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    func cardStyle(
        backgroundColor: Color = .navyCard,
        cornerRadius: CGFloat = 16
    ) -> some View {
        modifier(CardModifier(backgroundColor: backgroundColor, cornerRadius: cornerRadius))
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    let isActive: Bool
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive && isPulsing ? 1.05 : 1.0)
            .animation(
                isActive ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                value: isPulsing
            )
            .onAppear { if isActive { isPulsing = true } }
            .onChange(of: isActive) { isPulsing = $0 }
    }
}

extension View {
    func pulse(isActive: Bool = true) -> some View {
        modifier(PulseModifier(isActive: isActive))
    }
}

// MARK: - Premium Locked

struct PremiumLockedModifier: ViewModifier {
    let isLocked: Bool
    let onTap: () -> Void

    func body(content: Content) -> some View {
        content
            .opacity(isLocked ? 0.5 : 1.0)
            .overlay {
                if isLocked {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { onTap() }
                }
            }
            .allowsHitTesting(!isLocked)
    }
}

extension View {
    func premiumLocked(_ isLocked: Bool, onTap: @escaping () -> Void) -> some View {
        modifier(PremiumLockedModifier(isLocked: isLocked, onTap: onTap))
    }
}

// MARK: - Keyboard

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
