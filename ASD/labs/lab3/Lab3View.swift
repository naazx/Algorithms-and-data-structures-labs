//
//  Lab3View.swift
//  ASD
//
//  Created by Nazar Dydyn on 30.09.2026.
//

import SwiftUI

struct Lab3View: View {
    @Environment(StatsStore.self) private var stats

    @State private var countAText: String = "10"
    @State private var countBText: String = "10"

    @State private var totalA: Int = 0
    @State private var totalB: Int = 0
    @State private var formedCount: Int = 0
    @State private var previewA: [Int] = []
    @State private var previewB: [Int] = []
    @State private var previewFormed: [Int] = []
    @State private var previewAfter: [Int] = []
    @State private var elapsedMs: Double? = nil
    @State private var sortedResult: Bool? = nil
    @State private var errorMessage: String? = nil
    @State private var runID = 0

    private let lab = LabCatalog.lab(3)
    private let previewLimit = 20
    private let presets = [10, 100, 1_000, 100_000]

    var body: some View {
        LabScreen(lab: lab, scrollTrigger: runID) {
            Card(title: "Вхідні дані", systemImage: "slider.horizontal.3", tint: lab.tint) {
                NumberField(title: "Розмір масиву A", systemImage: "a.square.fill",
                            text: $countAText, presets: presets, tint: lab.tint)
                Divider()
                NumberField(title: "Розмір масиву B", systemImage: "b.square.fill",
                            text: $countBText, presets: presets, tint: .indigo)
                Text("Елементи генеруються випадково в діапазоні від −1000 до 1000.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = errorMessage {
                ErrorBanner(message: error)
            }

            if let sorted = sortedResult, let ms = elapsedMs {
                results(sorted: sorted, ms: ms)
                    .id(LabScreen<EmptyView, EmptyView>.resultsAnchor)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        } bar: {
            RunButton(title: "Сформувати й сортувати", tint: lab.tint) { runSort() }
        }
        .sensoryFeedback(.success, trigger: runID)
    }

    @ViewBuilder
    private func results(sorted: Bool, ms: Double) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            MetricTile(title: "Розмір A", value: Format.count(totalA), systemImage: "a.square.fill", tint: lab.tint)
            MetricTile(title: "Розмір B", value: Format.count(totalB), systemImage: "b.square.fill", tint: .indigo)
            MetricTile(title: "У результаті", value: Format.count(formedCount),
                       systemImage: "arrow.triangle.merge", tint: .green)
            MetricTile(title: "Час сортування", value: Format.milliseconds(ms), systemImage: "timer", tint: .orange)
        }

        SortedBadge(isSorted: sorted, text: sorted ? "Масив упорядковано" : "Масив не впорядковано")

        Card(title: "Масив A — беремо парні", systemImage: "a.square", tint: lab.tint) {
            chips(previewA, total: totalA) { $0 % 2 == 0 ? lab.tint : nil }
        }

        Card(title: "Масив B — беремо непарні", systemImage: "b.square", tint: .indigo) {
            chips(previewB, total: totalB) { $0 % 2 != 0 ? .indigo : nil }
        }

        Card(title: "Сформований масив", systemImage: "square.stack", tint: .secondary) {
            chips(previewFormed, total: formedCount) { $0 % 2 == 0 ? lab.tint : .indigo }
        }

        Card(title: "Результат", systemImage: "checkmark.circle", tint: .green) {
            chips(previewAfter, total: formedCount) { _ in .green }
        }
    }

    private func chips(_ values: [Int], total: Int, tint: @escaping (Int) -> Color?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if values.isEmpty {
                Text("Порожньо")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            FlowLayout(spacing: 6) {
                ForEach(values.indices, id: \.self) { i in
                    ValueChip(text: String(values[i]), tint: tint(values[i]))
                }
            }
            TruncationNote(shown: values.count, total: total)
        }
    }

    private func runSort() {
        errorMessage = nil

        guard let nA = Int(countAText), nA > 0,
              let nB = Int(countBText), nB > 0 else {
            errorMessage = "Введи коректні розміри масивів."
            return
        }

        let a = generateArray(count: nA)
        let b = generateArray(count: nB)
        previewA = Array(a.prefix(previewLimit))
        previewB = Array(b.prefix(previewLimit))

        let formed = formArray(a, b)
        previewFormed = Array(formed.prefix(previewLimit))

        let clock = ContinuousClock()
        let start = clock.now

        let result = mergeSort(formed)

        let elapsed = clock.now - start

        sortedResult = isSorted(result)

        elapsedMs = elapsed.milliseconds
        previewAfter = Array(result.prefix(previewLimit))
        totalA = nA
        totalB = nB
        formedCount = result.count

        stats.record(lab: lab.id, elements: result.count, milliseconds: elapsedMs, isSorted: sortedResult)
        runID += 1
    }
}

#Preview {
    NavigationStack { Lab3View() }
        .environment(StatsStore())
}
