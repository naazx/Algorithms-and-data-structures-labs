//
//  Lab1View.swift
//  ASD
//
//  Created by Nazar Dydyn on 18.09.2026.
//

import SwiftUI

struct Lab1View: View {
    @State private var inputText: String = ""
    @State private var randomCount: String = "10"
    @State private var isManualMode = true

    @State private var originalArray: [Double] = []
    @State private var sortedArray: [Double] = []
    @State private var elapsedTime: Double? = nil
    @State private var errorMessage: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text("Лабораторна робота №1 — Сортування Шелла")
                    .font(.title2).bold()

                Picker("Режим", selection: $isManualMode) {
                    Text("Ввести вручну").tag(true)
                    Text("Згенерувати").tag(false)
                }
                .pickerStyle(.segmented)

                if isManualMode {
                    Text("Введи числа через кому (можна від'ємні):")
                        .font(.caption)
                    TextField("напр: 3, -1, 8, 2, -4, 9", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                } else {
                    HStack {
                        Text("Кількість елементів:")
                        TextField("10", text: $randomCount)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
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

                if !originalArray.isEmpty {
                    Divider()

                    Text("Початковий масив:")
                        .font(.headline)
                    arrayView(originalArray)

                    Text("Результат:")
                        .font(.headline)
                    arrayView(sortedArray)

                    if let time = elapsedTime {
                        Text("Час виконання: \(String(format: "%.6f", time)) с")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func arrayView(_ array: [Double]) -> some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(array.indices, id: \.self) { i in
                    Text(formatted(array[i]))
                        .padding(8)
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(6)
                }
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value)
    }

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
    }
}
