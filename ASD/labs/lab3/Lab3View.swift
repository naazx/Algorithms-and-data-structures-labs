//
//  Lab3View.swift
//  ASD
//
//  Created by Nazar Dydyn on 30.09.2026.
//

import SwiftUI

struct Lab3View: View {
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

    private let previewLimit = 20

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text("Лабораторна робота №3 — Сортування злиттям")
                    .font(.title2).bold()

                Text("Варіант 10: парні з масиву A і непарні з масиву B за зростанням")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text("Розмір масиву A:")
                    TextField("10", text: $countAText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }

                HStack {
                    Text("Розмір масиву B:")
                    TextField("10", text: $countBText)
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

                    Text("Розмір A: \(totalA), розмір B: \(totalB), у результаті: \(formedCount)")
                        .font(.subheadline)

                    Text("Масив A:")
                        .font(.headline)
                    intList(previewA, total: totalA)

                    Text("Масив B:")
                        .font(.headline)
                    intList(previewB, total: totalB)

                    Text("Сформований масив (до сортування):")
                        .font(.headline)
                    intList(previewFormed, total: formedCount)

                    Text("Результат:")
                        .font(.headline)
                    intList(previewAfter, total: formedCount)

                    Text("Масив упорядковано: \(sorted ? "так" : "ні")")
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
    private func intList(_ values: [Int], total: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(values.map { String($0) }.joined(separator: ", "))
            if total > values.count {
                Text("… показано \(values.count) з \(total)")
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

        elapsedMs = Double(elapsed.components.seconds) * 1_000
                  + Double(elapsed.components.attoseconds) / 1e15
        previewAfter = Array(result.prefix(previewLimit))
        totalA = nA
        totalB = nB
        formedCount = result.count
    }
}
