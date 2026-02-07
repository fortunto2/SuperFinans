//
//  GuideContentView.swift
//  SuperFinans
//
//  Displays parsed Markdown content with SF Symbol icons.
//

import SwiftUI

struct GuideContentView: View {

    let contentType: MarkdownService.ContentType

    @State private var document: MarkdownDocument?

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if let document = document {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Introduction
                        if let intro = document.introduction, !intro.isEmpty {
                            Text(intro)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)
                        }

                        // Sections
                        ForEach(document.sections) { section in
                            sectionCard(section)
                        }

                        Spacer().frame(height: 32)
                    }
                    .padding(.top, 16)
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(document?.title ?? "")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { loadContent() }
    }

    // MARK: - Section Card

    private func sectionCard(_ section: MarkdownSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                if let symbol = section.sfSymbol {
                    Image(systemName: symbol)
                        .font(.system(size: 22))
                        .foregroundStyle(Color.goalMint)
                        .frame(width: 32)
                }

                Text(section.title)
                    .font(.system(size: 17, weight: .semibold))
            }

            Text(section.body)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .lineSpacing(4)
                .padding(.leading, section.sfSymbol != nil ? 44 : 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .padding(.horizontal, 20)
    }

    private func loadContent() {
        document = MarkdownService.shared.loadContent(contentType)
    }
}

#Preview {
    NavigationStack {
        GuideContentView(contentType: .gettingStarted)
    }
}
