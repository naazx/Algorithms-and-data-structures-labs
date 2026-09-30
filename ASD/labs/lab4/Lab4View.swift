//
//  Lab4View.swift
//  ASD
//
//  Created by Nazar Dydyn on 30.09.2026.
//

import SwiftUI

struct Lab4View: View {
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

    private let previewRows = 10
    private let previewCols = 8

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text("Лабораторна робота №4 — Сортування підрахунком")
                    .font(.title2).bold()

                Text("Варіант 11: максимуми рядків замінити на ∛x, рядки впорядкувати за першими елементами")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text("Кількість рядків:")
                    TextField("5", text: $rowsText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }

                HStack {
                    Text("Кількість стовпців:")
                    TextField("5", text: $colsText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }

                Button("Виконати") {
                    runSort()
                }
                .buttonStyle(.borderedProminent)

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if let sorted = sortedResult, let ms = elapsedMs {
                    Divider()

                    Text("Розмір матриці: \(totalRows) × \(totalCols)")
                        .font(.subheadline)

                    Text("Початкова матриця:")
                        .font(.headline)
                    matrixList(previewBefore)

                    Text("Після заміни максимумів на ∛x:")
                        .font(.headline)
                    matrixList(previewReplaced)

                    Text("Результат:")
                        .font(.headline)
                    matrixList(previewAfter)

                    Text("Матрицю впорядковано: \(sorted ? "так" : "ні")")
                        .foregroundColor(sorted ? .green : .red)

                    Text("Час сортування: \(String(format: "%.6f", ms)) мс")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func matrixList(_ rows: [[Double]]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(rows.indices, id: \.self) { i in
                let shown = rows[i].prefix(previewCols)
                    .map { String(format: "%.1f", $0) }
                    .joined(separator: "   ")
                Text(rows[i].count > previewCols ? shown + "   …" : shown)
                    .font(.system(.caption, design: .monospaced))
            }
            if totalRows > rows.count {
                Text("… показано \(rows.count) з \(totalRows) рядків")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
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

        elapsedMs = Double(elapsed.components.seconds) * 1_000
                  + Double(elapsed.components.attoseconds) / 1e15
        previewAfter = Array(result.prefix(previewRows))
        totalRows = r
        totalCols = c
    }
}
