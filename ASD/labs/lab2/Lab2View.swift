//
//  Lab2View.swift
//  ASD
//
//  Created by Nazar Dydyn on 25.09.2026.
//

import SwiftUI

struct Lab2View: View {
    @State private var countText: String = "10"

    @State private var totalCount: Int = 0
    @State private var filteredCount: Int = 0
    @State private var previewBefore: [Student] = []
    @State private var previewAfter: [Student] = []
    @State private var elapsedMs: Double? = nil
    @State private var sortedResult: Bool? = nil
    @State private var errorMessage: String? = nil

    private let previewLimit = 20

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text("Лабораторна робота №2 — Швидке сортування")
                    .font(.title2).bold()

                Text("Варіант 2: студенти з балом > 4 за алфавітом")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text("Кількість студентів:")
                    TextField("10", text: $countText)
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

                    Text("Усього студентів: \(totalCount), з балом > 4: \(filteredCount)")
                        .font(.subheadline)

                    Text("Початковий список:")
                        .font(.headline)
                    studentList(previewBefore, total: totalCount)

                    Text("Результат:")
                        .font(.headline)
                    studentList(previewAfter, total: filteredCount)

                    Text("Список упорядковано: \(sorted ? "так" : "ні")")
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
    private func studentList(_ students: [Student], total: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(students.indices, id: \.self) { i in
                HStack {
                    Text(students[i].name)
                    Spacer()
                    Text(String(format: "%.1f", students[i].average))
                        .foregroundColor(.secondary)
                }
            }
            if total > students.count {
                Text("… показано \(students.count) з \(total)")
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

        // 1. Кількість студентів
        guard let n = Int(countText), n > 0 else {
            errorMessage = "Введи коректну кількість студентів."
            return
        }

        // 2–3. Список рівно на n студентів із псевдовипадковими даними
        let students = generateStudents(count: n)
        previewBefore = Array(students.prefix(previewLimit))

        // Варіант: лишаємо тільки студентів із балом > 4
        var selected = studentsAbove4(students)

        // 4. Час початку
        let clock = ContinuousClock()
        let start = clock.now

        // 5. Сортування за алфавітом
        quickSort(&selected, index: 0, index: selected.count - 1)

        // 6. Час закінчення
        let elapsed = clock.now - start

        // 7. Перевірка
        sortedResult = isSorted(selected)

        // 8. Результат
        elapsedMs = Double(elapsed.components.seconds) * 1_000
                  + Double(elapsed.components.attoseconds) / 1e15
        previewAfter = Array(selected.prefix(previewLimit))
        totalCount = n
        filteredCount = selected.count

        // 9. students і selected — локальні змінні,
        //    ARC звільнить їх, щойно runSort() завершиться.
    }
}
