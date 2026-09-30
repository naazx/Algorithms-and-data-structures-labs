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
    @State private var model = BenchmarkModel()
    @State private var limitText: String = "300"
    @State private var quickTest: Bool = true
    @State private var errorMessage: String? = nil

    private let allSizes = [1024, 4096, 16384, 65536, 262144, 1048576, 4194304]
    private let lineWidths: [CGFloat] = [1.5, 2.5, 3.5, 4.5]
    private let dashes: [[CGFloat]] = [[], [8, 4], [2, 3], [10, 4, 2, 4]]

    private var names: [String] { BenchmarkModel.methodNames }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text("Лабораторна робота №5 — Порівняння методів сортування")
                    .font(.title2).bold()

                Text("Варіант 12: елементи після максимального впорядкувати за спаданням")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Toggle("Швидкий тест (розміри до 65 536)", isOn: $quickTest)

                HStack {
                    Text("Ліміт на один прогін, с:")
                    TextField("300", text: $limitText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                }

                HStack {
                    Button("Запустити") {
                        startBenchmark()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.isRunning)

                    Button("Зупинити") {
                        model.stop()
                    }
                    .disabled(!model.isRunning)
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                if !model.status.isEmpty {
                    Text(model.status)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if !model.results.isEmpty {
                    Divider()

                    Text("Таблиця часу сортування, мс")
                        .font(.headline)
                    timeTable

                    Text("∞ — метод не завершився за встановлений ліміт часу")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Графік часу сортування")
                        .font(.headline)
                    lineChart

                    barSection

                    Text("Усі результати впорядковані: \(model.allSorted ? "так" : "ні")")
                        .foregroundColor(model.allSorted ? .green : .red)
                }
            }
            .padding()
        }
    }

    private var timeTable: some View {
        ScrollView(.horizontal) {
            Grid(alignment: .trailing, horizontalSpacing: 14, verticalSpacing: 6) {
                GridRow {
                    Text("Метод").bold()
                    ForEach(model.sizes.indices, id: \.self) { s in
                        Text(String(model.sizes[s])).bold()
                    }
                }
                Divider()
                ForEach(names.indices, id: \.self) { m in
                    GridRow {
                        Text(names[m])
                        ForEach(model.sizes.indices, id: \.self) { s in
                            Text(cellText(model.results[m][s]))
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
            }
            .padding(8)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(6)
    }

    private func cellText(_ value: Double?) -> String {
        guard let value else { return "…" }
        if value.isInfinite { return "∞" }
        return String(format: "%.3f", value)
    }

    private var lineChart: some View {
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
        .chartXScale(type: .log)
        .chartYScale(type: .log)
        .chartXAxisLabel("Розмір масиву")
        .chartYAxisLabel("Час, мс")
        .frame(height: 320)
    }

    @ViewBuilder
    private var barSection: some View {
        if let last = model.sizes.indices.last {
            Text("Порівняння методів для розміру \(model.sizes[last])")
                .font(.headline)

            Chart {
                ForEach(names.indices, id: \.self) { m in
                    if let ms = model.results[m][last], ms.isFinite {
                        BarMark(
                            x: .value("Метод", names[m]),
                            y: .value("Час, мс", ms)
                        )
                        .foregroundStyle(by: .value("Метод", names[m]))
                        .annotation(position: .top) {
                            Text(String(format: "%.1f", ms))
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartYAxisLabel("Час, мс")
            .frame(height: 300)
        }
    }

    private func startBenchmark() {
        errorMessage = nil

        guard let limit = Double(limitText), limit > 0 else {
            errorMessage = "Введи коректний ліміт часу в секундах."
            return
        }

        let sizes = quickTest ? Array(allSizes.prefix(4)) : allSizes
        model.start(sizes: sizes, limitSeconds: limit)
    }
}
