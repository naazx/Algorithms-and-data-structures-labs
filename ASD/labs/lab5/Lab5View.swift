//
//  Lab5View.swift
//  ASD
//
//  Created by Nazar Dydyn on 30.09.2026.
//

import SwiftUI
import Charts
import Observation

@MainActor
@Observable
final class BenchmarkModel {
    static let methodNames = ["Шелла", "Швидке", "Злиттям", "Підрахунком"]

    var sizes: [Int] = []
    var results: [[Double?]] = []
    var isRunning = false
    var allSorted = true
    var status = ""

    private var task: Task<Void, Never>?

    func start(sizes: [Int], limitSeconds: Double) {
        guard !isRunning else { return }

        self.sizes = sizes
        results = Array(
            repeating: Array(repeating: nil, count: sizes.count),
            count: Self.methodNames.count
        )
        allSorted = true
        isRunning = true

        task = Task {
            var timedOut = Set<Int>()

            for (s, size) in sizes.enumerated() {
                if Task.isCancelled { break }

                status = "Генерація масиву розміром \(size)…"
                let source = await Task.detached(priority: .userInitiated) {
                    elementsAfterMax(generateBenchmarkArray(count: size))
                }.value

                for m in 0..<Self.methodNames.count {
                    if Task.isCancelled { break }

                    if timedOut.contains(m) {
                        results[m][s] = Double.infinity
                        continue
                    }

                    status = "\(Self.methodNames[m]), розмір \(size)…"
                    let outcome = await Task.detached(priority: .userInitiated) {
                        measureSort(method: m, source: source, limitSeconds: limitSeconds)
                    }.value

                    if let ms = outcome.milliseconds {
                        results[m][s] = ms
                        if !outcome.isSorted {
                            allSorted = false
                        }
                    } else {
                        results[m][s] = Double.infinity
                        timedOut.insert(m)
                    }
                }
            }

            status = Task.isCancelled ? "Зупинено" : "Готово"
            isRunning = false
        }
    }

    func stop() {
        task?.cancel()
    }
}

struct Lab5View: View {
    @Environment(StatsStore.self) private var stats

    @State private var model = BenchmarkModel()
    @State private var limitText: String = "300"
    @State private var quickTest: Bool = true
    @State private var errorMessage: String? = nil
    @State private var runID = 0

    private let lab = LabCatalog.lab(5)
    private let allSizes = [1024, 4096, 16384, 65536, 262144, 1048576, 4194304]
    private let lineWidths: [CGFloat] = [1.5, 2.5, 3.5, 4.5]
    private let dashes: [[CGFloat]] = [[], [8, 4], [2, 3], [10, 4, 2, 4]]
    private let methodColors: [Color] = [.indigo, .orange, .teal, .pink]

    private var names: [String] { BenchmarkModel.methodNames }
    private var plannedSizes: [Int] { quickTest ? Array(allSizes.prefix(4)) : allSizes }

    private var completedCells: Int {
        model.results.reduce(0) { $0 + $1.filter { $0 != nil }.count }
    }

    private var totalCells: Int {
        names.count * model.sizes.count
    }

    var body: some View {
        LabScreen(lab: lab, scrollTrigger: runID) {
            settingsCard

            if let error = errorMessage {
                ErrorBanner(message: error)
            }

            if !model.results.isEmpty {
                Group {
                    progressCard
                    tableCard
                    lineChartCard
                    barChartCard
                    if !model.isRunning {
                        SortedBadge(isSorted: model.allSorted,
                                    text: model.allSorted ? "Усі результати впорядковані" : "Є невпорядковані результати")
                    }
                }
                .id(LabScreen<EmptyView, EmptyView>.resultsAnchor)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        } bar: {
            if model.isRunning {
                RunButton(title: "Зупинити", systemImage: "stop.fill", tint: .red) {
                    model.stop()
                }
            } else {
                RunButton(title: "Запустити порівняння", systemImage: "play.fill", tint: lab.tint) {
                    startBenchmark()
                }
            }
        }
        .sensoryFeedback(.success, trigger: runID)
        .onChange(of: model.isRunning) { wasRunning, isRunning in
            if wasRunning && !isRunning {
                recordFinishedRun()
            }
        }
    }

    // MARK: - Settings

    private var settingsCard: some View {
        Card(title: "Налаштування", systemImage: "slider.horizontal.3", tint: lab.tint) {
            Toggle(isOn: $quickTest.animation(.snappy)) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Швидкий тест")
                        Text("Розміри до 65 536 елементів")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "hare.fill")
                }
            }
            .tint(lab.tint)
            .disabled(model.isRunning)

            Divider()

            NumberField(title: "Ліміт на прогін, с", systemImage: "hourglass",
                        text: $limitText, presets: [10, 60, 300, 600], tint: lab.tint)
                .disabled(model.isRunning)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Розміри масивів")
                    .font(.subheadline.weight(.medium))
                FlowLayout(spacing: 6) {
                    ForEach(plannedSizes, id: \.self) { size in
                        ValueChip(text: Format.count(size), tint: lab.tint)
                    }
                }
            }

            HStack(spacing: 6) {
                ForEach(names.indices, id: \.self) { m in
                    Pill(text: names[m], tint: methodColors[m])
                }
            }
        }
    }

    // MARK: - Progress

    private var progressCard: some View {
        Card {
            HStack(spacing: 12) {
                if model.isRunning {
                    ProgressView()
                } else {
                    Image(systemName: model.status == "Готово" ? "checkmark.circle.fill" : "stop.circle.fill")
                        .font(.title3)
                        .foregroundStyle(model.status == "Готово" ? .green : .orange)
                }
                Text(model.status)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Spacer()
                Text("\(completedCells) / \(totalCells)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            ProgressView(value: Double(completedCells), total: Double(max(totalCells, 1)))
                .tint(lab.tint)
                .animation(.snappy, value: completedCells)
        }
    }

    // MARK: - Table

    private var tableCard: some View {
        Card(title: "Час сортування, мс", systemImage: "tablecells", tint: lab.tint) {
            ScrollView(.horizontal, showsIndicators: false) {
                Grid(alignment: .trailing, horizontalSpacing: 16, verticalSpacing: 10) {
                    GridRow {
                        Text("Метод")
                            .gridColumnAlignment(.leading)
                        ForEach(model.sizes.indices, id: \.self) { s in
                            Text(Format.compact(model.sizes[s]))
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                    Divider()

                    ForEach(names.indices, id: \.self) { m in
                        GridRow {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(methodColors[m])
                                    .frame(width: 8, height: 8)
                                Text(names[m])
                                    .font(.subheadline.weight(.medium))
                            }
                            ForEach(model.sizes.indices, id: \.self) { s in
                                tableCell(method: m, size: s)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            HStack(spacing: 16) {
                LegendItem(color: .green, text: "найшвидший")
                Text("∞ — не завершився за ліміт")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func tableCell(method m: Int, size s: Int) -> some View {
        let value = model.results[m][s]
        let isFastest = value.map { v in
            v.isFinite && names.indices.allSatisfy { other in
                guard let o = model.results[other][s], o.isFinite else { return true }
                return v <= o
            }
        } ?? false

        Text(cellText(value))
            .font(.caption.monospacedDigit().weight(isFastest ? .bold : .regular))
            .foregroundStyle(isFastest ? .green : (value?.isInfinite == true ? .red : .primary))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(isFastest ? Color.green.opacity(0.12) : .clear, in: .rect(cornerRadius: 6))
    }

    private func cellText(_ value: Double?) -> String {
        guard let value else { return "…" }
        if value.isInfinite { return "∞" }
        return String(format: "%.3f", value)
    }

    // MARK: - Charts

    private var lineChartCard: some View {
        Card(title: "Залежність часу від розміру", systemImage: "chart.xyaxis.line", tint: lab.tint) {
            Chart {
                ForEach(names.indices, id: \.self) { m in
                    ForEach(model.sizes.indices, id: \.self) { s in
                        if let ms = model.results[m][s], ms.isFinite {
                            LineMark(
                                x: .value("Розмір масиву", model.sizes[s]),
                                y: .value("Час, мс", ms),
                                series: .value("Метод", names[m])
                            )
                            .foregroundStyle(by: .value("Метод", names[m]))
                            .lineStyle(StrokeStyle(lineWidth: lineWidths[m], dash: dashes[m]))
                            .symbol(by: .value("Метод", names[m]))
                        }
                    }
                }
            }
            .chartForegroundStyleScale(domain: names, range: methodColors)
            .chartXScale(type: .log)
            .chartYScale(type: .log)
            .chartXAxisLabel("Розмір масиву")
            .chartYAxisLabel("Час, мс")
            .chartLegend(position: .bottom, alignment: .leading)
            .frame(height: 300)

            Text("Обидві осі логарифмічні.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var barChartCard: some View {
        if let last = model.sizes.indices.last {
            Card(title: "Порівняння для \(Format.count(model.sizes[last])) елементів",
                 systemImage: "chart.bar.fill", tint: lab.tint) {
                Chart {
                    ForEach(names.indices, id: \.self) { m in
                        if let ms = model.results[m][last], ms.isFinite {
                            BarMark(
                                x: .value("Метод", names[m]),
                                y: .value("Час, мс", ms)
                            )
                            .foregroundStyle(by: .value("Метод", names[m]))
                            .cornerRadius(6)
                            .annotation(position: .top) {
                                Text(String(format: "%.1f", ms))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .chartForegroundStyleScale(domain: names, range: methodColors)
                .chartLegend(.hidden)
                .chartYAxisLabel("Час, мс")
                .frame(height: 260)
            }
        }
    }

    // MARK: - Actions

    private func startBenchmark() {
        errorMessage = nil

        guard let limit = Double(limitText), limit > 0 else {
            errorMessage = "Введи коректний ліміт часу в секундах."
            return
        }

        model.start(sizes: plannedSizes, limitSeconds: limit)
        runID += 1
    }

    private func recordFinishedRun() {
        var elements = 0
        for m in model.results.indices {
            for s in model.sizes.indices {
                if let ms = model.results[m][s], ms.isFinite {
                    elements += max(model.sizes[s] - 1, 0)
                }
            }
        }
        guard elements > 0 else { return }
        stats.record(lab: lab.id, elements: elements, isSorted: model.allSorted)
    }
}

#Preview {
    NavigationStack { Lab5View() }
        .environment(StatsStore())
}
