//
//  FreedomYearWidget.swift
//  SuperFinansWidget
//
//  The year you stop needing a salary, on the home screen. It is the one
//  number in personal finance worth glancing at daily — spending totals are
//  not, which is why every other finance widget gets ignored.
//

import SwiftUI
import WidgetKit

/// Mirrors Color.goalMintDark from the app. Duplicated rather than shared: the
/// widget target links the model, not the app's asset catalogue.
private extension Color {
    static let freedomMint = Color(red: 0x26 / 255, green: 0xA6 / 255, blue: 0x9A / 255)
}

struct FreedomEntry: TimelineEntry {
    let date: Date
    let plan: FreedomPlan?
    let outcome: FreedomOutcome?
}

struct FreedomProvider: TimelineProvider {

    func placeholder(in context: Context) -> FreedomEntry {
        let plan = FreedomPlan(
            monthlyExpensesMinor: 120_000,
            currentSavingsMinor: 3_000_000,
            monthlySavingsMinor: 80_000,
            birthYear: 1990,
            annualReturnPercent: FreedomPlan.defaultReturnPercent,
            currencyCode: "USD",
            shifts: []
        )
        return FreedomEntry(date: Date(), plan: plan, outcome: FreedomEngine.outcome(for: plan))
    }

    func getSnapshot(in context: Context, completion: @escaping (FreedomEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FreedomEntry>) -> Void) {
        // The answer moves in months, not minutes. One refresh a day is plenty
        // and keeps the widget off the system's naughty list.
        let next = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [currentEntry()], policy: .after(next)))
    }

    private func currentEntry() -> FreedomEntry {
        guard let plan = FreedomPlanStorage.loadPlan() else {
            return FreedomEntry(date: Date(), plan: nil, outcome: nil)
        }
        return FreedomEntry(date: Date(), plan: plan, outcome: FreedomEngine.outcome(for: plan))
    }
}

struct FreedomWidgetView: View {

    @Environment(\.widgetFamily) private var family
    let entry: FreedomEntry

    var body: some View {
        if let outcome = entry.outcome, let year = outcome.year {
            filled(year: year, outcome: outcome)
        } else {
            empty
        }
    }

    private func filled(year: Int, outcome: FreedomOutcome) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Free in")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(String(year))
                .font(.system(size: family == .systemSmall ? 40 : 52,
                              weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
                .foregroundStyle(Color.freedomMint)

            if let age = outcome.age {
                Text("you'll be \(age)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let years = outcome.years {
                Text("\(years) years away")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            ProgressView(value: outcome.currentRatio)
                .tint(Color.freedomMint)
            Text("\(outcome.currentRatio.formatted(.percent.precision(.fractionLength(0)))) covered")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "flag.checkered")
                .font(.title2)
                .foregroundStyle(Color.freedomMint)
            Text("When can you stop working?")
                .font(.footnote.bold())
            Text("Three numbers, one minute.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

struct FreedomYearWidget: Widget {

    let kind = "FreedomYearWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FreedomProvider()) { entry in
            FreedomWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Freedom year")
        .description("The year your investments cover your life.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct SuperFinansWidgetBundle: WidgetBundle {
    var body: some Widget {
        FreedomYearWidget()
    }
}
