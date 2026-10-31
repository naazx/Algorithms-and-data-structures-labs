//
//  Lab8View.swift
//  ASD
//
//  Created by Nazar Dydyn on 31.10.2026.
//

import SwiftUI
import Charts

// MARK: - Model

private struct CurvePoint: Identifiable {
    let size: Int
    let worst: Int
    let average: Double

    var id: Int { size }
}

private struct SearchReport {
    let array: [Int]
    let target: Int
    let result: SearchResult
    let rows: [ComplexityRow]
    let curve: [CurvePoint]

    var minimum: Int { array[0] }
}

// MARK: - View

struct Lab8View: View {
    @Environment(StatsStore.self) private var stats

    @State private var countText: String = "20"
    @State private var showLinear: Bool = true

    @State private var report: SearchReport? = nil
    @State private var errorMessage: String? = nil
    @State private var runID = 0

    private let lab = LabCatalog.lab(8)
    private let tableSizes = [10, 40, 70, 100]
    private let shownLimit = 60
    private let presets = [10, 40, 70, 100, 1000]

    var body: some View {
        LabScreen(lab: lab, scrollTrigger: runID) {
            inputCard

            if let error = errorMessage {
                ErrorBanner(message: error)
            }

            if let report {
                Group {
                    metrics(report)
                    arrayCard(report)
                    stepsCard(report)
                    tableCard(report)
                    chartCard(report)
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
        Card(title: "Вхідні дані", systemImage: "slider.horizontal.3", tint: lab.tint) {
            NumberField(title: "Кількість елементів", systemImage: "number",
                        text: $countText, presets: presets, tint: lab.tint)

            Text("Масив цілих чисел генерується автоматично й упорядковується за зростанням. Допустимо від 10 до 1000 елементів. Шукаємо елемент, більший за мінімальний на 10.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Results

    private func metrics(_ report: SearchReport) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            MetricTile(title: "Елементів у масиві", value: Format.count(report.array.count),
                       systemImage: "number", tint: lab.tint)
            MetricTile(title: "Мінімальний елемент", value: String(report.minimum),
                       systemImage: "arrow.down.to.line", tint: .indigo)
            MetricTile(title: "Шукане значення", value: String(report.target),
                       systemImage: "scope", tint: .purple)
            MetricTile(title: report.result.position == nil ? "Елемента немає" : "Позиція елемента",
                       value: report.result.position.map { String($0) } ?? "—",
                       systemImage: "mappin.and.ellipse",
                       tint: report.result.position == nil ? .orange : .green)
            MetricTile(title: "Порівнянь", value: String(report.result.comparisons),
                       systemImage: "equal.circle", tint: .pink)
            MetricTile(title: "Межа ⌊log₂ n⌋ + 1", value: String(comparisonBound(count: report.array.count)),
                       systemImage: "function", tint: .teal)
        }
    }

    private func arrayCard(_ report: SearchReport) -> some View {
        let shown = Array(report.array.prefix(shownLimit))

        return Card(title: "Упорядкований масив", systemImage: "list.number", tint: lab.tint) {
            FlowLayout(spacing: 6) {
                ForEach(shown.indices, id: \.self) { i in
                    ValueChip(text: String(shown[i]), tint: chipTint(index: i, report))
                }
            }

            HStack(spacing: 14) {
                LegendItem(color: .indigo, text: "мінімум")
                if report.result.position != nil {
                    LegendItem(color: .green, text: "знайдений")
                }
            }

            TruncationNote(shown: shown.count, total: report.array.count, unit: "елементів")
        }
    }

    private func chipTint(index: Int, _ report: SearchReport) -> Color? {
        if let position = report.result.position, index == position - 1 { return .green }
        if index == 0 { return .indigo }
        return nil
    }

    private func stepsCard(_ report: SearchReport) -> some View {
        Card(title: "Покрокове виконання", systemImage: "list.bullet.rectangle", tint: lab.tint) {
            Text("b = \(report.target). Відрізок k..l, середній індекс m = ⌊(k + l) / 2⌋, Buffer = A[m].")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(report.result.steps.indices, id: \.self) { i in
                let step = report.result.steps[i]
                HStack(alignment: .top, spacing: 12) {
                    Text("\(i + 1)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(outcomeColor(step.outcome).gradient, in: .circle)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("k = \(step.low), l = \(step.high), m = \(step.middle)")
                            .font(.subheadline.weight(.medium).monospacedDigit())
                        Text(outcomeText(step, target: report.target))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }

            if report.result.position == nil {
                Label("Відрізок порожній (l < k): елемента \(report.target) у масиві немає.",
                      systemImage: "xmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            }
        }
    }

    private func outcomeColor(_ outcome: StepOutcome) -> Color {
        switch outcome {
        case .found: .green
        case .goLeft: .orange
        case .goRight: .blue
        }
    }

    private func outcomeText(_ step: SearchStep, target: Int) -> String {
        switch step.outcome {
        case .found: "A[\(step.middle)] = \(step.value) = \(target): знайдено"
        case .goLeft: "A[\(step.middle)] = \(step.value) > \(target): шукаємо ліворуч"
        case .goRight: "A[\(step.middle)] = \(step.value) < \(target): шукаємо праворуч"
        }
    }

    private func tableCard(_ report: SearchReport) -> some View {
        Card(title: "Таблиця 1. Кількість порівнянь", systemImage: "tablecells", tint: lab.tint) {
            Grid(alignment: .trailing, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("n").gridColumnAlignment(.leading)
                    Text("Середнє")
                    Text("Найбільше")
                    Text("⌊log₂ n⌋ + 1")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

                Divider()

                ForEach(report.rows.indices, id: \.self) { i in
                    let row = report.rows[i]
                    GridRow {
                        Text(Format.count(row.count))
                            .font(.subheadline.weight(.semibold).monospacedDigit())
                        Text(String(format: "%.2f", row.average))
                        Text(String(row.worst))
                        Text(String(row.bound))
                    }
                    .font(.subheadline.monospacedDigit())
                }
            }

            Text("Для кожного розміру пошук виконано для всіх елементів масиву. Найбільша кількість порівнянь збігається з межею ⌊log₂ n⌋ + 1, тож C(n) = O(log n).")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func chartCard(_ report: SearchReport) -> some View {
        let names = showLinear
            ? ["y = n", "y = log₂ n", "C(n), найбільше", "C(n), середнє"]
            : ["y = log₂ n", "C(n), найбільше", "C(n), середнє"]
        let colors: [Color] = showLinear
            ? [.gray, .orange, lab.tint, .green]
            : [.orange, lab.tint, .green]

        return Card(title: "Залежність C(n) від n", systemImage: "chart.xyaxis.line", tint: lab.tint) {
            Toggle(isOn: $showLinear.animation(.snappy)) {
                Text("Показати y = n")
                    .font(.subheadline)
            }
            .tint(lab.tint)

            Chart {
                ForEach(report.curve) { point in
                    if showLinear {
                        LineMark(x: .value("n", point.size),
                                 y: .value("Порівнянь", Double(point.size)),
                                 series: .value("Графік", "y = n"))
                            .foregroundStyle(by: .value("Графік", "y = n"))
                    }
                    LineMark(x: .value("n", point.size),
                             y: .value("Порівнянь", log2(Double(point.size))),
                             series: .value("Графік", "y = log₂ n"))
                        .foregroundStyle(by: .value("Графік", "y = log₂ n"))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                    LineMark(x: .value("n", point.size),
                             y: .value("Порівнянь", Double(point.worst)),
                             series: .value("Графік", "C(n), найбільше"))
                        .foregroundStyle(by: .value("Графік", "C(n), найбільше"))
                    LineMark(x: .value("n", point.size),
                             y: .value("Порівнянь", point.average),
                             series: .value("Графік", "C(n), середнє"))
                        .foregroundStyle(by: .value("Графік", "C(n), середнє"))
                }
            }
            .chartForegroundStyleScale(domain: names, range: colors)
            .chartXAxisLabel("Кількість елементів n")
            .chartYAxisLabel("Кількість порівнянь")
            .chartLegend(position: .bottom, alignment: .leading)
            .frame(height: 300)

            Text("Графік y = n різко зростає, а C(n) повторює y = log₂ n, лише на 1–2 порівняння вище: C(n) ≈ ⌊log₂ n⌋ + 1.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Actions

    private func run() {
        errorMessage = nil

        guard let count = Int(countText), (10...1000).contains(count) else {
            errorMessage = "Введи кількість елементів від 10 до 1000."
            return
        }

        let array = generateSortedArray(count: count)
        guard let target = targetValue(for: array) else { return }

        let result = binarySearch(array, target: target)
        let rows = tableSizes.map { complexityRow(count: $0) }
        let curve = (1...100).map { size -> CurvePoint in
            let row = complexityRow(count: size)
            return CurvePoint(size: size, worst: row.worst, average: row.average)
        }

        report = SearchReport(array: array, target: target, result: result, rows: rows, curve: curve)

        stats.record(lab: lab.id, elements: count)
        runID += 1
    }
}

#Preview {
    NavigationStack { Lab8View() }
        .environment(StatsStore())
}
