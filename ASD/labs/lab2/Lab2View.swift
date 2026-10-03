//
//  Lab2View.swift
//  ASD
//
//  Created by Nazar Dydyn on 25.09.2026.
//

import SwiftUI

struct Lab2View: View {
    @Environment(StatsStore.self) private var stats

    @State private var countText: String = "10"

    @State private var totalCount: Int = 0
    @State private var filteredCount: Int = 0
    @State private var previewBefore: [Student] = []
    @State private var previewAfter: [Student] = []
    @State private var elapsedMs: Double? = nil
    @State private var sortedResult: Bool? = nil
    @State private var errorMessage: String? = nil
    @State private var runID = 0

    private let lab = LabCatalog.lab(2)
    private let previewLimit = 20

    var body: some View {
        LabScreen(lab: lab, scrollTrigger: runID) {
            Card(title: "Вхідні дані", systemImage: "slider.horizontal.3", tint: lab.tint) {
                NumberField(title: "Кількість студентів", systemImage: "person.3.fill",
                            text: $countText, presets: [10, 100, 1_000, 10_000, 100_000], tint: lab.tint)
                Text("Імена та середні бали (2.0–5.0) генеруються випадково.")
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
            RunButton(title: "Сортувати", tint: lab.tint) { runSort() }
        }
        .sensoryFeedback(.success, trigger: runID)
    }

    @ViewBuilder
    private func results(sorted: Bool, ms: Double) -> some View {
        HStack(spacing: 12) {
            MetricTile(title: "Усього студентів", value: Format.count(totalCount),
                       systemImage: "person.3.fill", tint: lab.tint)
            MetricTile(title: "З балом > 4", value: Format.count(filteredCount),
                       systemImage: "star.fill", tint: .green)
            MetricTile(title: "Час сортування", value: Format.milliseconds(ms),
                       systemImage: "timer", tint: .blue)
        }

        SortedBadge(isSorted: sorted, text: sorted ? "Список упорядковано" : "Список не впорядковано")

        Card(title: "Результат", systemImage: "list.bullet.rectangle", tint: lab.tint) {
            studentList(previewAfter, total: filteredCount, dimLowGrades: false)
        }

        Card(title: "Початковий список", systemImage: "shuffle", tint: .secondary) {
            studentList(previewBefore, total: totalCount, dimLowGrades: true)
        }
    }

    private func studentList(_ students: [Student], total: Int, dimLowGrades: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if students.isEmpty {
                Text("Немає студентів із балом понад 4.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ForEach(students.indices, id: \.self) { i in
                StudentRow(index: i + 1, student: students[i], tint: lab.tint)
                    .opacity(dimLowGrades && students[i].average <= 4 ? 0.45 : 1)
                if i < students.count - 1 {
                    Divider().padding(.leading, 76)
                }
            }
            TruncationNote(shown: students.count, total: total)
                .padding(.top, 8)
        }
    }

    private func runSort() {
        errorMessage = nil

        guard let n = Int(countText), n > 0 else {
            errorMessage = "Введи коректну кількість студентів."
            return
        }

        let students = generateStudents(count: n)
        previewBefore = Array(students.prefix(previewLimit))

        var selected = studentsAbove4(students)

        let clock = ContinuousClock()
        let start = clock.now

        quickSort(&selected, index: 0, index: selected.count - 1)

        let elapsed = clock.now - start

        sortedResult = isSorted(selected)

        elapsedMs = elapsed.milliseconds
        previewAfter = Array(selected.prefix(previewLimit))
        totalCount = n
        filteredCount = selected.count

        stats.record(lab: lab.id, elements: n, milliseconds: elapsedMs, isSorted: sortedResult)
        runID += 1
    }
}

private struct StudentRow: View {
    let index: Int
    let student: Student
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Text("\(index)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 24, alignment: .trailing)

            Text(String(student.name.prefix(1)))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.15), in: .circle)

            Text(student.name)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            let isHigh = student.average > 4
            Text(String(format: "%.1f", student.average))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(isHigh ? .green : .secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background((isHigh ? Color.green : .secondary).opacity(0.12), in: .capsule)
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    NavigationStack { Lab2View() }
        .environment(StatsStore())
}
