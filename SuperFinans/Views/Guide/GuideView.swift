//
//  GuideView.swift
//  SuperFinans
//
//  Main Guide view with subsections and language picker.
//

import SwiftUI

struct GuideView: View {

    @State private var selectedLanguage: String = MarkdownService.shared.currentLanguage

    var body: some View {
        List {
            // Language picker
            Section {
                Picker("Language", selection: $selectedLanguage) {
                    ForEach(MarkdownService.supportedLanguages, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                .onChange(of: selectedLanguage) { _, newValue in
                    MarkdownService.shared.currentLanguage = newValue
                }
            }

            Section {
                guideRow(
                    title: selectedLanguage == "ru" ? "Начало работы" : "Getting Started",
                    subtitle: selectedLanguage == "ru" ? "Создайте первую цель за 60 секунд" : "Set up your first goal in 60 seconds",
                    icon: "sparkles",
                    color: .goalMint,
                    contentType: .gettingStarted
                )
            }

            Section(selectedLanguage == "ru" ? "Функции" : "Features") {
                guideRow(
                    title: selectedLanguage == "ru" ? "Цели" : "Goals",
                    subtitle: selectedLanguage == "ru" ? "Накопления и сложный процент" : "Savings targets & compound interest",
                    icon: "star.fill",
                    color: .goalMint,
                    contentType: .goals
                )

                guideRow(
                    title: selectedLanguage == "ru" ? "Транзакции" : "Transactions",
                    subtitle: selectedLanguage == "ru" ? "Доходы и расходы" : "Track income & expenses",
                    icon: "list.bullet.rectangle.portrait",
                    color: .blue,
                    contentType: .transactions
                )

                guideRow(
                    title: selectedLanguage == "ru" ? "Аналитика" : "Insights",
                    subtitle: selectedLanguage == "ru" ? "Графики и тренды расходов" : "Spending charts & trends",
                    icon: "chart.bar.fill",
                    color: .orange,
                    contentType: .insights
                )
            }

            Section {
                guideRow(
                    title: "Premium",
                    subtitle: selectedLanguage == "ru" ? "$29.99 разово — всё включено" : "$29.99 one-time — everything unlocked",
                    icon: "crown.fill",
                    color: .yellow,
                    contentType: .premium
                )

                guideRow(
                    title: selectedLanguage == "ru" ? "Приватность" : "Privacy & Security",
                    subtitle: selectedLanguage == "ru" ? "Офлайн, без слежки" : "Offline-first, no tracking",
                    icon: "lock.shield.fill",
                    color: .green,
                    contentType: .privacy
                )
            }

            Section {
                guideRow(
                    title: selectedLanguage == "ru" ? "О приложении" : "About",
                    subtitle: selectedLanguage == "ru" ? "Зачем мы создали это приложение" : "Why we built this app",
                    icon: "info.circle.fill",
                    color: .secondary,
                    contentType: .about
                )
            }
        }
        .navigationTitle(selectedLanguage == "ru" ? "Гайд" : "Guide")
        .navigationBarTitleDisplayMode(.large)
    }

    private func guideRow(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        contentType: MarkdownService.ContentType
    ) -> some View {
        NavigationLink {
            GuideContentView(contentType: contentType)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    NavigationStack {
        GuideView()
    }
}
