//
//  Lab4View.swift
//  ASD
//
//  Created by Nazar Dydyn on 30.09.2026.
//

import SwiftUI

struct Lab4View: View {
    @Environment(StatsStore.self) private var stats

    @State private var rowsText: String = "5"
    @State private var colsText: String = "5"

    @State private var totalRows: Int = 0
    @State private var totalCols: Int = 0
    @State private var previewBefore: [[Double]] = []
    @State private var previewReplaced: [[Double]] = []
    @State private var previewAfter: [[Double]] = []
    @State private var elapsedMs: Double? = nil
    @State private var sortedResult: Bool? = nil
    @State private var errorMessage: String? = nil
    @State private var runID = 0

    private let lab = LabCatalog.lab(4)
    private let previewRows = 10
    private let previewCols = 8

    var body: some View {
        LabScreen(lab: lab, scrollTrigger: runID) {
            Card(title: "Розмір матриці", systemImage: "slider.horizontal.3", tint: lab.tint) {
                NumberField(title: "Рядків", systemImage: "arrow.down.to.line",
                            text: $rowsText, presets: [3, 5, 10, 100, 10_000], tint: lab.tint)
                Divider()
                NumberField(title: "Стовпців", systemImage: "arrow.right.to.line",
                            text: $colsText, presets: [3, 5, 8, 20], tint: lab.tint)
                Text("Елементи генеруються випадково в діапазоні від −100.0 до 100.0.")
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
            RunButton(title: "Обробити матрицю", tint: lab.tint) { runSort() }
        }
        .sensoryFeedback(.success, trigger: runID)
    }

    @ViewBuilder
    private func results(sorted: Bool, ms: Double) -> some View {
        HStack(spacing: 12) {
            MetricTile(title: "Розмір", value: "\(Format.compact(totalRows)) × \(Format.compact(totalCols))",
                       systemImage: "square.grid.3x3.fill", tint: lab.tint)
            MetricTile(title: "Час сортування", value: Format.milliseconds(ms),
                       systemImage: "timer", tint: .orange)
        }

        SortedBadge(isSorted: sorted, text: sorted ? "Матрицю впорядковано" : "Матрицю не впорядковано")

        Card(title: "1. Початкова матриця", systemImage: "square.grid.3x3", tint: .secondary) {
            MatrixView(rows: previewBefore, totalRows: totalRows, previewCols: previewCols) { i, j in
                previewBefore[i][j] == previewBefore[i].max() ? .orange : nil
            }
            LegendItem(color: .orange, text: "максимум рядка")
        }

        Card(title: "2. Заміна максимумів на ∛x", systemImage: "function", tint: lab.tint) {
            MatrixView(rows: previewReplaced, totalRows: totalRows, previewCols: previewCols) { i, j in
                previewReplaced[i][j] != previewBefore[i][j] ? lab.tint : nil
            }
            LegendItem(color: lab.tint, text: "замінене значення")
        }

        Card(title: "3. Результат", systemImage: "checkmark.circle", tint: .green) {
            MatrixView(rows: previewAfter, totalRows: totalRows, previewCols: previewCols) { _, j in
                j == 0 ? .green : nil
            }
            LegendItem(color: .green, text: "ключ сортування — перший стовпець")
        }
    }

    private func runSort() {
        errorMessage = nil

        guard let r = Int(rowsText), r > 0,
              let c = Int(colsText), c > 0 else {
            errorMessage = "Введи коректні розміри матриці."
            return
        }

        let matrix = generateMatrix(rows: r, cols: c)
        previewBefore = Array(matrix.prefix(previewRows))

        let replaced = replaceMaxWithCbrt(matrix)
        previewReplaced = Array(replaced.prefix(previewRows))

        let clock = ContinuousClock()
        let start = clock.now

        let result = countingSortRows(replaced)

        let elapsed = clock.now - start

        sortedResult = isSorted(result)

        elapsedMs = elapsed.milliseconds
        previewAfter = Array(result.prefix(previewRows))
        totalRows = r
        totalCols = c

        stats.record(lab: lab.id, elements: r * c, milliseconds: elapsedMs, isSorted: sortedResult)
        runID += 1
    }
}

private struct MatrixView: View {
    let rows: [[Double]]
    let totalRows: Int
    let previewCols: Int
    let highlight: (Int, Int) -> Color?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                    ForEach(rows.indices, id: \.self) { i in
                        GridRow {
                            ForEach(0..<min(previewCols, rows[i].count), id: \.self) { j in
                                cell(String(format: "%.1f", rows[i][j]), tint: highlight(i, j))
                            }
                            if rows[i].count > previewCols {
                                Text("…")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            TruncationNote(shown: rows.count, total: totalRows, unit: "рядків")
        }
    }

    private func cell(_ text: String, tint: Color?) -> some View {
        Text(text)
            .font(.caption.monospacedDigit().weight(tint == nil ? .regular : .semibold))
            .foregroundStyle(tint ?? .primary)
            .frame(minWidth: 52)
            .padding(.vertical, 6)
            .background((tint ?? .secondary).opacity(tint == nil ? 0.08 : 0.16),
                        in: .rect(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    NavigationStack { Lab4View() }
        .environment(StatsStore())
}
