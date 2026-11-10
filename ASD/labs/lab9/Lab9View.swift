//
//  Lab9View.swift
//  ASD
//
//  Created by Nazar Dydyn on 10.11.2026.
//

import SwiftUI

// MARK: - Model

private struct KMPReport {
    let original: String
    let swap: SwapResult
    let secondText: [Character]
    let prefix: [Int]
    let prefixMilliseconds: Double
    let kmp: SearchOutcome
    let kmpMilliseconds: Double
    let naive: SearchOutcome
    let naiveMilliseconds: Double
    let rows: [BenchmarkRow]

    var pattern: [Character] { Array(swap.pattern) }
}

// MARK: - View

struct Lab9View: View {
    @Environment(StatsStore.self) private var stats

    @State private var firstText: String = Lab9View.sampleFirst
    @State private var secondText: String = Lab9View.sampleSecond

    @State private var report: KMPReport? = nil
    @State private var errorMessage: String? = nil
    @State private var runID = 0

    private let lab = LabCatalog.lab(9)
    private let benchmarkSizes = [1_000, 10_000, 50_000, 100_000]
    private let benchmarkPatternLength = 10
    private let shownLimit = 1_500
    private let shownPositions = 60

    private static let sampleFirst = "ми з'їли ананас"
    private static let sampleSecond = "ананананасми та ананасми, ананасми"

    var body: some View {
        LabScreen(lab: lab, scrollTrigger: runID) {
            inputCard

            if let error = errorMessage {
                ErrorBanner(message: error)
            }

            if let report {
                Group {
                    metrics(report)
                    swapCard(report)
                    patternCard(report)
                    matchesCard(report)
                    tableCard(report)
                }
                .id(LabScreen<EmptyView, EmptyView>.resultsAnchor)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        } bar: {
            RunButton(title: "Виконати пошук", systemImage: "magnifyingglass", tint: lab.tint) {
                run()
            }
        }
        .sensoryFeedback(.success, trigger: runID)
    }

    // MARK: - Input

    private var inputCard: some View {
        Card(title: "Вхідні дані", systemImage: "text.alignleft", tint: lab.tint) {
            TextInput(title: "Перший текст", systemImage: "1.circle", text: $firstText)

            Divider()

            TextInput(title: "Другий текст", systemImage: "2.circle", text: $secondText)

            HStack(alignment: .top, spacing: 12) {
                Text("У першому тексті слова міняються місцями, а в другому шукається їх об'єднання: найдовше + найкоротше. Пошук чутливий до регістру.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    firstText = Lab9View.sampleFirst
                    secondText = Lab9View.sampleSecond
                    hideKeyboard()
                } label: {
                    Label("Приклад", systemImage: "wand.and.stars")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .foregroundStyle(lab.tint)
                        .background(lab.tint.opacity(0.12), in: .capsule)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Results

    private func metrics(_ report: KMPReport) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            MetricTile(title: "Слів у першому тексті", value: Format.count(report.swap.words.count),
                       systemImage: "textformat", tint: lab.tint)
            MetricTile(title: "Входжень у другий текст", value: Format.count(report.kmp.positions.count),
                       systemImage: "scope", tint: report.kmp.positions.isEmpty ? .orange : .green)
            MetricTile(title: "Час префікс-функції", value: Format.milliseconds(report.prefixMilliseconds),
                       systemImage: "timer", tint: .indigo)
            MetricTile(title: "Час пошуку КМП", value: Format.milliseconds(report.kmpMilliseconds),
                       systemImage: "bolt.fill", tint: .purple)
            MetricTile(title: "Порівнянь КМП", value: Format.count(report.kmp.comparisons),
                       systemImage: "equal.circle", tint: .pink)
            MetricTile(title: "Порівнянь прямого пошуку", value: Format.count(report.naive.comparisons),
                       systemImage: "equal.circle", tint: .teal)
        }
    }

    private func swapCard(_ report: KMPReport) -> some View {
        Card(title: "Обмін слів у першому тексті", systemImage: "arrow.left.arrow.right", tint: lab.tint) {
            FlowLayout(spacing: 6) {
                ValueChip(text: "найдовше: \(report.swap.longest)", tint: .orange)
                ValueChip(text: "найкоротше: \(report.swap.shortest)", tint: .indigo)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Було")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(report.original)
                    .font(.body)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Стало")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(report.swap.swappedText)
                    .font(.body.weight(.medium))
            }
        }
    }

    private func patternCard(_ report: KMPReport) -> some View {
        let pattern = report.pattern

        return Card(title: "Взірець і префікс-функція", systemImage: "function", tint: lab.tint) {
            Text("P = «\(report.swap.longest)» + «\(report.swap.shortest)» = «\(report.swap.pattern)»")
                .font(.subheadline.weight(.medium))

            ScrollView(.horizontal, showsIndicators: false) {
                Grid(horizontalSpacing: 12, verticalSpacing: 8) {
                    GridRow {
                        Text("i").gridColumnAlignment(.leading)
                        ForEach(pattern.indices, id: \.self) { index in
                            Text(String(index + 1))
                        }
                    }
                    .foregroundStyle(.secondary)

                    GridRow {
                        Text("P[i]")
                        ForEach(pattern.indices, id: \.self) { index in
                            Text(String(pattern[index]))
                                .fontWeight(.semibold)
                        }
                    }

                    GridRow {
                        Text("D(i)")
                        ForEach(pattern.indices, id: \.self) { index in
                            Text(String(report.prefix[index]))
                                .foregroundStyle(report.prefix[index] > 0 ? lab.tint : .secondary)
                                .fontWeight(report.prefix[index] > 0 ? .bold : .regular)
                        }
                    }
                }
                .font(.subheadline.monospacedDigit())
            }

            Text("D(i) — довжина найбільшого префікса слова P[1..i], який є також його суфіксом. Саме на цю величину КМП повертається в слові після неспівпадіння, не перечитуючи текст.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func matchesCard(_ report: KMPReport) -> some View {
        let positions = report.kmp.positions

        return Card(title: "Входження у другий текст", systemImage: "text.magnifyingglass", tint: lab.tint) {
            Text(highlightedText(report))
                .font(.body)

            TruncationNote(shown: min(report.secondText.count, shownLimit),
                           total: report.secondText.count, unit: "символів")

            if positions.isEmpty {
                Label("Взірець «\(report.swap.pattern)» у другому тексті не знайдено.",
                      systemImage: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            } else {
                Text("Позиції початку входжень (нумерація з 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 6) {
                    ForEach(positions.prefix(shownPositions), id: \.self) { position in
                        ValueChip(text: String(position + 1), tint: .green)
                    }
                }

                TruncationNote(shown: min(positions.count, shownPositions),
                               total: positions.count, unit: "позицій")
            }
        }
    }

    private func tableCard(_ report: KMPReport) -> some View {
        Card(title: "Таблиця 3. КМП і прямий пошук", systemImage: "tablecells", tint: lab.tint) {
            Grid(alignment: .trailing, horizontalSpacing: 8, verticalSpacing: 10) {
                GridRow {
                    Text("n").gridColumnAlignment(.leading)
                    Text("КМП, мс")
                    Text("Порівн.")
                    Text("Прямий, мс")
                    Text("Порівн.")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                Divider()

                ForEach(report.rows.indices, id: \.self) { index in
                    let row = report.rows[index]
                    GridRow {
                        Text(Format.count(row.size))
                            .fontWeight(.semibold)
                        Text(String(format: "%.3f", row.kmpMilliseconds))
                        Text(Format.count(row.kmpComparisons))
                        Text(String(format: "%.3f", row.naiveMilliseconds))
                        Text(Format.count(row.naiveComparisons))
                    }
                    .font(.footnote.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
            }

            Text("Текст із n літер «a», взірець «aaaaaaaaab» (m = \(benchmarkPatternLength)) — найгірший вхід для прямого пошуку: він робить ≈ n·m порівнянь, а КМП лише ≈ 2n. Складність КМП: O(m) на префікс-функцію та O(n) на пошук, разом O(n + m).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func highlightedText(_ report: KMPReport) -> AttributedString {
        let shown = Array(report.secondText.prefix(shownLimit))
        var isMatch = [Bool](repeating: false, count: shown.count)

        for position in report.kmp.positions where position < shown.count {
            for offset in 0..<report.pattern.count where position + offset < shown.count {
                isMatch[position + offset] = true
            }
        }

        var result = AttributedString()
        for index in shown.indices {
            var piece = AttributedString(String(shown[index]))
            if isMatch[index] {
                piece.foregroundColor = Color.green
                piece.backgroundColor = Color.green.opacity(0.2)
            }
            result += piece
        }
        return result
    }

    // MARK: - Actions

    private func run() {
        errorMessage = nil

        let first = firstText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !first.isEmpty else {
            errorMessage = "Введи перший текст."
            return
        }
        guard let swap = swapLongestAndShortest(in: first) else {
            errorMessage = "У першому тексті має бути щонайменше два слова різної довжини."
            return
        }

        let second = Array(secondText)
        guard !second.isEmpty else {
            errorMessage = "Введи другий текст."
            return
        }

        let pattern = Array(swap.pattern)
        let prefixRun = measure { prefixFunction(pattern) }
        let kmpRun = measure { kmpSearch(text: second, pattern: pattern, prefix: prefixRun.value) }
        let naiveRun = measure { naiveSearch(text: second, pattern: pattern) }
        let rows = benchmarkSizes.map { benchmarkRow(size: $0, patternLength: benchmarkPatternLength) }

        report = KMPReport(
            original: first,
            swap: swap,
            secondText: second,
            prefix: prefixRun.value,
            prefixMilliseconds: prefixRun.milliseconds,
            kmp: kmpRun.value,
            kmpMilliseconds: kmpRun.milliseconds,
            naive: naiveRun.value,
            naiveMilliseconds: naiveRun.milliseconds,
            rows: rows
        )

        stats.record(lab: lab.id, elements: second.count, milliseconds: kmpRun.milliseconds)
        runID += 1
    }
}

// MARK: - Text input

private struct TextInput: View {
    let title: String
    let systemImage: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))

            TextField("Введи текст", text: $text, axis: .vertical)
                .lineLimit(2...6)
                .autocorrectionDisabled()
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.subtleFill, in: .rect(cornerRadius: 14, style: .continuous))
        }
    }
}

#Preview {
    NavigationStack { Lab9View() }
        .environment(StatsStore())
}
