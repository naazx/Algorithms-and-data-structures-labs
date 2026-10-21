//
//  Lab6View.swift
//  ASD
//
//  Created by Nazar Dydyn on 21.10.2026.
//

import SwiftUI

// MARK: - Model

private struct InputError: Error {
    let message: String
}

/// Знімок характеристик черги для відображення.
private struct QueueReport {
    let values: [Double]
    let count: Int
    let minValue: Double?
    let maxValue: Double?
    let third: Double?
    let secondFromEnd: Double?
    let beforeMin: Double?
    let afterMax: Double?
    let target: Double?
    let position: Int?

    init(queue: Queue, target: Double?) {
        var collected: [Double] = []
        queue.forEach { collected.append($0) }
        values = collected
        count = queue.count

        let extremes = queue.minMax()
        minValue = extremes?.min
        maxValue = extremes?.max

        third = queue.thirdFromStart()
        secondFromEnd = queue.secondFromEnd()
        beforeMin = queue.beforeMin()
        afterMax = queue.afterMax()

        self.target = target
        position = target.flatMap { queue.position(of: $0) }
    }
}

// MARK: - View

struct Lab6View: View {
    @Environment(StatsStore.self) private var stats

    @State private var aText: String = "5 -2.5 8 1 7.25 3"
    @State private var bText: String = "4 9.5 -1"
    @State private var searchText: String = "8"

    @State private var reportA: QueueReport? = nil
    @State private var reportB: QueueReport? = nil
    @State private var reportMerged: QueueReport? = nil
    @State private var errorMessage: String? = nil
    @State private var runID = 0

    private let lab = LabCatalog.lab(6)

    var body: some View {
        LabScreen(lab: lab, scrollTrigger: runID) {
            inputCard

            if let error = errorMessage {
                ErrorBanner(message: error)
            }

            if let a = reportA, let b = reportB, let merged = reportMerged {
                Group {
                    queueCard(title: "Черга A", systemImage: "a.square.fill", tint: lab.tint, report: a)
                    queueCard(title: "Черга B", systemImage: "b.square.fill", tint: .indigo, report: b)
                    queueCard(title: "Об'єднана черга (A + B)", systemImage: "arrow.triangle.merge",
                              tint: .green, report: merged)
                }
                .id(LabScreen<EmptyView, EmptyView>.resultsAnchor)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        } bar: {
            RunButton(title: "Побудувати й проаналізувати", systemImage: "play.fill", tint: lab.tint) {
                run()
            }
        }
        .sensoryFeedback(.success, trigger: runID)
    }

    // MARK: - Input

    private var inputCard: some View {
        Card(title: "Вхідні дані", systemImage: "square.and.pencil", tint: lab.tint) {
            SequenceField(title: "Черга A", systemImage: "a.square.fill", text: $aText, tint: lab.tint)

            Divider()

            SequenceField(title: "Черга B", systemImage: "b.square.fill", text: $bText, tint: .indigo)

            Divider()

            HStack {
                Label("Знайти позицію", systemImage: "magnifyingglass")
                    .font(.subheadline.weight(.medium))
                Spacer(minLength: 12)
                TextField("число", text: $searchText)
                    .keyboardType(.numbersAndPunctuation)
                    .multilineTextAlignment(.trailing)
                    .font(.body.monospacedDigit().weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .frame(maxWidth: 130)
                    .background(Color.subtleFill, in: .capsule)
            }

            Text("Числа розділяй пробілом або «;». Усередині кожної черги вони не повторюються.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Results

    private func queueCard(title: String, systemImage: String, tint: Color, report: QueueReport) -> some View {
        Card(title: title, systemImage: systemImage, tint: tint) {
            strip(report, tint: tint)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                MetricTile(title: "Кількість елементів", value: Format.count(report.count),
                           systemImage: "number", tint: tint)
                MetricTile(title: report.target.map { "Позиція числа \(Format.number($0))" } ?? "Позиція (не задано)",
                           value: report.position.map { String($0) } ?? "—",
                           systemImage: "magnifyingglass", tint: .purple)
                MetricTile(title: "Мінімум", value: report.minValue.map(Format.number) ?? "—",
                           systemImage: "arrow.down.to.line", tint: .blue)
                MetricTile(title: "Максимум", value: report.maxValue.map(Format.number) ?? "—",
                           systemImage: "arrow.up.to.line", tint: .orange)
            }

            Divider()

            CharacteristicRow(title: "Третій з початку", systemImage: "3.circle",
                              value: report.third.map(Format.number))
            CharacteristicRow(title: "Другий з кінця", systemImage: "2.circle",
                              value: report.secondFromEnd.map(Format.number))
            CharacteristicRow(title: "Перед мінімумом", systemImage: "arrow.left.circle",
                              value: report.beforeMin.map(Format.number))
            CharacteristicRow(title: "Після максимуму", systemImage: "arrow.right.circle",
                              value: report.afterMax.map(Format.number))
        }
    }

    private func strip(_ report: QueueReport, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let first = report.values.first, let last = report.values.last {
                HStack(spacing: 6) {
                    Pill(text: "Голова: \(Format.number(first))", systemImage: "arrow.right.to.line", tint: tint)
                    Pill(text: "Хвіст: \(Format.number(last))", systemImage: "arrow.left.to.line", tint: .secondary)
                }

                FlowLayout(spacing: 6) {
                    ForEach(report.values.indices, id: \.self) { i in
                        let value = report.values[i]
                        ValueChip(text: Format.number(value), tint: chipTint(value, report))
                    }
                }

                HStack(spacing: 14) {
                    LegendItem(color: .blue, text: "мінімум")
                    LegendItem(color: .orange, text: "максимум")
                }
            } else {
                Text("Порожня черга")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func chipTint(_ value: Double, _ report: QueueReport) -> Color? {
        if value == report.minValue { return .blue }
        if value == report.maxValue { return .orange }
        return nil
    }

    // MARK: - Actions

    private func run() {
        errorMessage = nil

        do {
            let queueA = try buildQueue(from: aText, name: "A")
            let queueB = try buildQueue(from: bText, name: "B")

            guard !queueA.isEmpty() || !queueB.isEmpty() else {
                throw InputError(message: "Введи хоча б одне число.")
            }

            let target = try parseTarget()
            let merged = queueA.merged(with: queueB)

            reportA = QueueReport(queue: queueA, target: target)
            reportB = QueueReport(queue: queueB, target: target)
            reportMerged = QueueReport(queue: merged, target: target)

            stats.record(lab: lab.id, elements: merged.count)
            runID += 1
        } catch let error as InputError {
            errorMessage = error.message
        } catch {
            errorMessage = "Не вдалося обробити введені дані."
        }
    }

    private func buildQueue(from text: String, name: String) throws -> Queue {
        let queue = Queue()
        let tokens = text.split { $0 == " " || $0 == ";" || $0 == "\n" }

        for token in tokens {
            let normalized = token.replacingOccurrences(of: ",", with: ".")
            guard let value = Double(normalized), value.isFinite else {
                throw InputError(message: "Черга \(name): «\(token)» не є числом.")
            }
            if !queue.enqueueUnique(value) {
                throw InputError(message: "Черга \(name): число \(Format.number(value)) повторюється.")
            }
        }
        return queue
    }

    private func parseTarget() throws -> Double? {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        guard let value = Double(trimmed.replacingOccurrences(of: ",", with: ".")), value.isFinite else {
            throw InputError(message: "Значення для пошуку «\(trimmed)» не є числом.")
        }
        return value
    }
}

// MARK: - Components

private struct SequenceField: View {
    let title: String
    let systemImage: String
    @Binding var text: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button {
                    text = randomSequence()
                    hideKeyboard()
                } label: {
                    Label("Випадково", systemImage: "dice.fill")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .foregroundStyle(tint)
                        .background(tint.opacity(0.12), in: .capsule)
                }
                .buttonStyle(.plain)
            }

            TextField("наприклад: 3 -1.5 8", text: $text, axis: .vertical)
                .keyboardType(.numbersAndPunctuation)
                .font(.body.monospacedDigit())
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.subtleFill, in: .rect(cornerRadius: 14, style: .continuous))
        }
        .sensoryFeedback(.selection, trigger: text)
    }

    private func randomSequence(count: Int = 8) -> String {
        var used = Set<Int>()
        while used.count < count {
            used.insert(Int.random(in: -500...500))
        }
        return used.map { Format.number(Double($0) / 10) }.joined(separator: " ")
    }
}

private struct CharacteristicRow: View {
    let title: String
    let systemImage: String
    let value: String?

    var body: some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
            Spacer(minLength: 12)
            Text(value ?? "—")
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(value == nil ? .secondary : .primary)
        }
    }
}

#Preview {
    NavigationStack { Lab6View() }
        .environment(StatsStore())
}
