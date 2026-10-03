//
//  Lab1View.swift
//  ASD
//
//  Created by Nazar Dydyn on 18.09.2026.
//

import SwiftUI

struct Lab1View: View {
    @Environment(StatsStore.self) private var stats

    @State private var inputText: String = ""
    @State private var randomCount: String = "10"
    @State private var isManualMode = true

    @State private var originalArray: [Double] = []
    @State private var sortedArray: [Double] = []
    @State private var elapsedTime: Double? = nil
    @State private var errorMessage: String? = nil
    @State private var runID = 0

    private let lab = LabCatalog.lab(1)
    private let previewLimit = 120
    private let sampleInput = "3, -1, 8, 2, -4, 9, 5, -7, 1"

    /// Indices strictly between the first and last negative elements.
    private var sortedRange: Range<Int>? {
        guard let range = findNegativeRange(in: originalArray),
              range.last - range.first > 1 else { return nil }
        return (range.first + 1)..<range.last
    }

    private var segmentIsSorted: Bool {
        guard let range = sortedRange else { return true }
        let segment = sortedArray[range]
        return zip(segment, segment.dropFirst()).allSatisfy { $0 <= $1 }
    }

    var body: some View {
        LabScreen(lab: lab, scrollTrigger: runID) {
            inputCard

            if let error = errorMessage {
                ErrorBanner(message: error)
            }

            if !originalArray.isEmpty {
                results
                    .id(LabScreen<EmptyView, EmptyView>.resultsAnchor)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        } bar: {
            RunButton(title: "Сортувати", tint: lab.tint) { runSort() }
        }
        .sensoryFeedback(.success, trigger: runID)
    }

    // MARK: - Input

    private var inputCard: some View {
        Card(title: "Вхідні дані", systemImage: "slider.horizontal.3", tint: lab.tint) {
            Picker("Режим", selection: $isManualMode.animation(.snappy)) {
                Label("Вручну", systemImage: "keyboard").tag(true)
                Label("Згенерувати", systemImage: "dice").tag(false)
            }
            .pickerStyle(.segmented)

            if isManualMode {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Числа через кому, напр. \(sampleInput)", text: $inputText, axis: .vertical)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                        .lineLimit(2...5)
                        .font(.body.monospacedDigit())
                        .padding(12)
                        .background(Color.subtleFill, in: .rect(cornerRadius: 14, style: .continuous))

                    HStack {
                        Button("Приклад", systemImage: "text.badge.plus") {
                            inputText = sampleInput
                        }
                        Spacer()
                        if !inputText.isEmpty {
                            Button("Очистити", systemImage: "xmark.circle", role: .destructive) {
                                inputText = ""
                            }
                        }
                    }
                    .font(.footnote.weight(.medium))
                    .buttonStyle(.borderless)
                }
            } else {
                NumberField(title: "Кількість елементів", systemImage: "number",
                            text: $randomCount, presets: [10, 20, 50, 100, 1000], tint: lab.tint)
                Text("Значення генеруються випадково в діапазоні від −50 до 50.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Results

    @ViewBuilder
    private var results: some View {
        HStack(spacing: 12) {
            MetricTile(title: "Елементів", value: Format.count(originalArray.count),
                       systemImage: "number", tint: lab.tint)
            MetricTile(title: "Відсортовано", value: Format.count(sortedRange?.count ?? 0),
                       systemImage: "arrow.up.right", tint: .teal)
            MetricTile(title: "Час", value: elapsedTime.map { Format.milliseconds($0 * 1_000) } ?? "—",
                       systemImage: "timer", tint: .orange)
        }

        if sortedRange == nil {
            Label("Між від'ємними числами немає елементів для сортування — масив не змінився.",
                  systemImage: "info.circle.fill")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color.cardBackground, in: .rect(cornerRadius: 16, style: .continuous))
        } else {
            SortedBadge(isSorted: segmentIsSorted)
        }

        Card(title: "Початковий масив", systemImage: "list.number", tint: .secondary) {
            arrayChips(originalArray)
        }

        Card(title: "Результат", systemImage: "checkmark.circle", tint: lab.tint) {
            arrayChips(sortedArray)
        }

        HStack(spacing: 16) {
            LegendItem(color: .red, text: "від'ємні")
            LegendItem(color: lab.tint, text: "відрізок для сортування")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private func arrayChips(_ array: [Double]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            FlowLayout(spacing: 6) {
                ForEach(array.indices.prefix(previewLimit), id: \.self) { i in
                    ValueChip(text: Format.number(array[i]), tint: chipTint(index: i, value: array[i]))
                }
            }
            TruncationNote(shown: min(previewLimit, array.count), total: array.count)
        }
    }

    private func chipTint(index: Int, value: Double) -> Color? {
        if value < 0 { return .red }
        if sortedRange?.contains(index) == true { return lab.tint }
        return nil
    }

    // MARK: - Actions

    private func runSort() {
        errorMessage = nil

        if isManualMode {
            let parts = inputText.split(separator: ",")
            let numbers = parts.compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
            guard numbers.count == parts.count, !numbers.isEmpty else {
                errorMessage = "Перевір формат вводу — тільки числа через кому."
                return
            }
            originalArray = numbers
        } else {
            guard let count = Int(randomCount), count > 0 else {
                errorMessage = "Введи коректну кількість елементів."
                return
            }
            originalArray = (0..<count).map { _ in Double(Int.random(in: -50...50)) }
        }

        var working = originalArray
        let start = Date()
        sortBetweenNegatives(&working)
        elapsedTime = Date().timeIntervalSince(start)
        sortedArray = working

        stats.record(lab: lab.id, elements: originalArray.count,
                     milliseconds: elapsedTime.map { $0 * 1_000 }, isSorted: segmentIsSorted)
        runID += 1
    }
}

#Preview {
    NavigationStack { Lab1View() }
        .environment(StatsStore())
}
