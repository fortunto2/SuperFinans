//
//  MarkdownService.swift
//  SuperFinans
//
//  Loads and parses Markdown content files for the Guide section.
//  Supports en/ru with in-app language override.
//

import Foundation

// MARK: - Parsed Content Models

struct MarkdownSection: Identifiable {
    let id = UUID()
    let title: String
    let sfSymbol: String?
    let body: String
}

struct MarkdownDocument {
    let title: String
    let introduction: String?
    let sections: [MarkdownSection]
}

// MARK: - MarkdownService

final class MarkdownService {

    static let shared = MarkdownService()

    private init() {}

    enum ContentType: String {
        case gettingStarted = "getting_started"
        case goals = "goals_guide"
        case transactions = "transactions_guide"
        case insights = "insights_guide"
        case privacy = "privacy_guide"
        case premium = "premium_guide"
        case about = "about"
    }

    // MARK: - Language

    /// In-app language override. Stored in UserDefaults.
    var currentLanguage: String {
        get { UserDefaults.standard.string(forKey: "superfinans.guide_language") ?? autoDetectedLanguage }
        set { UserDefaults.standard.set(newValue, forKey: "superfinans.guide_language") }
    }

    private var autoDetectedLanguage: String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("ru") { return "ru" }
        return "en"
    }

    static let supportedLanguages: [(code: String, name: String)] = [
        ("en", "English"),
        ("ru", "Русский")
    ]

    // MARK: - Loading

    func loadContent(_ type: ContentType) -> MarkdownDocument? {
        let lang = currentLanguage

        // Russian files are prefixed with ru_
        if lang == "ru" {
            let ruFilename = "ru_\(type.rawValue)"
            if let url = Bundle.main.url(forResource: ruFilename, withExtension: "md") {
                if let content = try? String(contentsOf: url, encoding: .utf8) {
                    return parseMarkdown(content)
                }
            }
        }

        // English / fallback — no prefix
        if let url = Bundle.main.url(forResource: type.rawValue, withExtension: "md") {
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                return parseMarkdown(content)
            }
        }

        return nil
    }

    // MARK: - Parsing

    private func parseMarkdown(_ content: String) -> MarkdownDocument {
        let lines = content.components(separatedBy: .newlines)

        var title = ""
        var introLines: [String] = []
        var sections: [MarkdownSection] = []

        var currentTitle: String?
        var currentSymbol: String?
        var currentBody: [String] = []
        var foundFirstSection = false

        for line in lines {
            if line.hasPrefix("# ") && title.isEmpty {
                title = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                continue
            }

            if line.hasPrefix("## ") {
                if let sTitle = currentTitle {
                    let body = currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    sections.append(MarkdownSection(title: sTitle, sfSymbol: currentSymbol, body: body))
                }

                foundFirstSection = true
                currentTitle = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                currentSymbol = nil
                currentBody = []
                continue
            }

            if line.hasPrefix("![") && line.hasSuffix("]") {
                let symbolName = String(line.dropFirst(2).dropLast(1))
                if currentTitle != nil {
                    currentSymbol = symbolName
                }
                continue
            }

            if !foundFirstSection && !title.isEmpty {
                if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    introLines.append(line)
                }
            } else if currentTitle != nil {
                currentBody.append(line)
            }
        }

        if let sTitle = currentTitle {
            let body = currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            sections.append(MarkdownSection(title: sTitle, sfSymbol: currentSymbol, body: body))
        }

        let introduction = introLines.isEmpty ? nil : introLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)

        return MarkdownDocument(title: title, introduction: introduction, sections: sections)
    }
}
