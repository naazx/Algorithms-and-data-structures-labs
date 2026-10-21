//
//  Lab7View.swift
//  ASD
//
//  Created by Nazar Dydyn on 21.10.2026.
//

import SwiftUI

// MARK: - Model

private struct InputError: Error {
    let message: String
}

private struct TreeVertex: Identifiable {
    let value: Double
    let column: Int
    let depth: Int
    let parent: Double?

    var id: Double { value }
}

private struct Relatives {
    let parent: Double?
    let left: Double?
    let right: Double?
}

/// Знімок дерева для відображення.
private struct TreeReport {
    let count: Int
    let levels: Int
    let preorder: [Double]
    let secondLargest: Double?
    let target: Double?
    let isFound: Bool
    let relatives: Relatives?
    let vertices: [TreeVertex]

    init(tree: BinarySearchTree, target: Double?) {
        count = tree.count

        var visited: [Double] = []
        tree.preorder { visited.append($0) }
        preorder = visited

        secondLargest = tree.secondLargest()

        self.target = target
        if let target {
            isFound = tree.contains(target)
            relatives = tree.relatives(of: target).map {
                Relatives(parent: $0.parent, left: $0.left, right: $0.right)
            }
        } else {
            isFound = false
            relatives = nil
        }

        var layout: [TreeVertex] = []
        var column = 0
        func walk(_ node: TreeNode?, depth: Int, parent: Double?) {
            guard let node else { return }
            walk(node.left, depth: depth + 1, parent: node.value)
            layout.append(TreeVertex(value: node.value, column: column, depth: depth, parent: parent))
            column += 1
            walk(node.right, depth: depth + 1, parent: node.value)
        }
        walk(tree.root, depth: 0, parent: nil)

        vertices = layout
        levels = (layout.map(\.depth).max() ?? -1) + 1
    }
}

// MARK: - View

struct Lab7View: View {
    @Environment(StatsStore.self) private var stats

    @State private var sequenceText: String = "8 3 10 1 6 14 4 7 13.5"
    @State private var searchText: String = "6"

    @State private var report: TreeReport? = nil
    @State private var errorMessage: String? = nil
    @State private var runID = 0

    private let lab = LabCatalog.lab(7)

    var body: some View {
        LabScreen(lab: lab, scrollTrigger: runID) {
            inputCard

            if let error = errorMessage {
                ErrorBanner(message: error)
            }

            if let report {
                Group {
                    metrics(report)
                    treeCard(report)
                    preorderCard(report)
                    searchCard(report)
                }
                .id(LabScreen<EmptyView, EmptyView>.resultsAnchor)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        } bar: {
            RunButton(title: "Побудувати дерево", systemImage: "play.fill", tint: lab.tint) {
                run()
            }
        }
        .sensoryFeedback(.success, trigger: runID)
    }

    // MARK: - Input

    private var inputCard: some View {
        Card(title: "Вхідні дані", systemImage: "square.and.pencil", tint: lab.tint) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Послідовність чисел", systemImage: "list.number")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Button {
                        sequenceText = randomSequence()
                        hideKeyboard()
                    } label: {
                        Label("Випадково", systemImage: "dice.fill")
                            .font(.footnote.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundStyle(lab.tint)
                            .background(lab.tint.opacity(0.12), in: .capsule)
                    }
                    .buttonStyle(.plain)
                }

                TextField("наприклад: 8 3 10 1 6", text: $sequenceText, axis: .vertical)
                    .keyboardType(.numbersAndPunctuation)
                    .font(.body.monospacedDigit())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.subtleFill, in: .rect(cornerRadius: 14, style: .continuous))
            }
            .sensoryFeedback(.selection, trigger: sequenceText)

            Divider()

            HStack {
                Label("Шукана вершина", systemImage: "magnifyingglass")
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

            Text("Числа розділяй пробілом або «;». Усі значення в дереві різні, тому повтор вважається помилкою.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Results

    private func metrics(_ report: TreeReport) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            MetricTile(title: "Вершин у дереві", value: Format.count(report.count),
                       systemImage: "circle.grid.cross", tint: lab.tint)
            MetricTile(title: "Рівнів (висота)", value: Format.count(report.levels),
                       systemImage: "arrow.down.to.line", tint: .indigo)
            MetricTile(title: "Другий за спаданням", value: report.secondLargest.map(Format.number) ?? "—",
                       systemImage: "2.circle.fill", tint: .purple)
            MetricTile(title: report.target.map { "Значення \(Format.number($0)) у дереві" } ?? "Пошук не задано",
                       value: report.target == nil ? "—" : (report.isFound ? "Так" : "Ні"),
                       systemImage: "magnifyingglass", tint: report.isFound ? .green : .orange)
        }
    }

    private func treeCard(_ report: TreeReport) -> some View {
        Card(title: "Бінарне дерево пошуку", systemImage: "point.3.connected.trianglepath.dotted", tint: lab.tint) {
            TreeDiagram(vertices: report.vertices,
                        levels: report.levels,
                        target: report.isFound ? report.target : nil,
                        relatives: report.relatives,
                        tint: lab.tint)

            HStack(spacing: 14) {
                LegendItem(color: lab.tint, text: "шукана")
                LegendItem(color: .orange, text: "батько")
                LegendItem(color: .green, text: "нащадки")
            }
        }
    }

    private func preorderCard(_ report: TreeReport) -> some View {
        Card(title: "Низхідний обхід", systemImage: "arrow.down.right", tint: lab.tint) {
            Text("корінь → ліве піддерево → праве піддерево")
                .font(.caption)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: 6) {
                ForEach(report.preorder.indices, id: \.self) { i in
                    let value = report.preorder[i]
                    ValueChip(text: Format.number(value), tint: chipTint(value, report))
                }
            }

            HStack(spacing: 14) {
                LegendItem(color: .purple, text: "другий за спаданням")
                if report.isFound {
                    LegendItem(color: lab.tint, text: "шукана")
                }
            }
        }
    }

    @ViewBuilder
    private func searchCard(_ report: TreeReport) -> some View {
        if let target = report.target {
            Card(title: "Вершина \(Format.number(target))", systemImage: "scope", tint: lab.tint) {
                if let relatives = report.relatives {
                    CharacteristicRow(title: "Батько", systemImage: "arrow.up.circle",
                                      value: relatives.parent.map(Format.number))
                    CharacteristicRow(title: "Лівий нащадок", systemImage: "arrow.down.left.circle",
                                      value: relatives.left.map(Format.number))
                    CharacteristicRow(title: "Правий нащадок", systemImage: "arrow.down.right.circle",
                                      value: relatives.right.map(Format.number))
                } else {
                    Label("Такого значення в дереві немає.", systemImage: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private func chipTint(_ value: Double, _ report: TreeReport) -> Color? {
        if value == report.secondLargest { return .purple }
        if report.isFound && value == report.target { return lab.tint }
        return nil
    }

    // MARK: - Actions

    private func run() {
        errorMessage = nil

        do {
            let tree = try buildTree()
            guard !tree.isEmpty() else {
                throw InputError(message: "Введи хоча б одне число.")
            }
            report = TreeReport(tree: tree, target: try parseTarget())

            stats.record(lab: lab.id, elements: tree.count)
            runID += 1
        } catch let error as InputError {
            errorMessage = error.message
        } catch {
            errorMessage = "Не вдалося обробити введені дані."
        }
    }

    private func buildTree() throws -> BinarySearchTree {
        let tree = BinarySearchTree()
        let tokens = sequenceText.split { $0 == " " || $0 == ";" || $0 == "\n" }

        for token in tokens {
            let normalized = token.replacingOccurrences(of: ",", with: ".")
            guard let value = Double(normalized), value.isFinite else {
                throw InputError(message: "«\(token)» не є числом.")
            }
            if !tree.insert(value) {
                throw InputError(message: "Число \(Format.number(value)) повторюється, а значення в дереві мають бути різними.")
            }
        }
        return tree
    }

    private func parseTarget() throws -> Double? {
        let trimmed = searchText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        guard let value = Double(trimmed.replacingOccurrences(of: ",", with: ".")), value.isFinite else {
            throw InputError(message: "Шукане значення «\(trimmed)» не є числом.")
        }
        return value
    }

    private func randomSequence(count: Int = 9) -> String {
        var used = Set<Int>()
        while used.count < count {
            used.insert(Int.random(in: -500...500))
        }
        return used.map { Format.number(Double($0) / 10) }.joined(separator: " ")
    }
}

// MARK: - Components

private struct TreeDiagram: View {
    let vertices: [TreeVertex]
    let levels: Int
    let target: Double?
    let relatives: Relatives?
    let tint: Color

    private let columnWidth: CGFloat = 46
    private let rowHeight: CGFloat = 64
    private let nodeSize: CGFloat = 40

    private var width: CGFloat { CGFloat(vertices.count) * columnWidth }
    private var height: CGFloat { CGFloat(levels - 1) * rowHeight + nodeSize + 8 }

    private func point(_ vertex: TreeVertex) -> CGPoint {
        CGPoint(x: CGFloat(vertex.column) * columnWidth + columnWidth / 2,
                y: CGFloat(vertex.depth) * rowHeight + nodeSize / 2 + 4)
    }

    private func role(_ vertex: TreeVertex) -> Color? {
        if vertex.value == target { return tint }
        if let relatives {
            if vertex.value == relatives.parent { return .orange }
            if vertex.value == relatives.left || vertex.value == relatives.right { return .green }
        }
        return nil
    }

    var body: some View {
        let lookup = Dictionary(uniqueKeysWithValues: vertices.map { ($0.value, $0) })

        ScrollView(.horizontal, showsIndicators: false) {
            ZStack(alignment: .topLeading) {
                Canvas { context, _ in
                    for vertex in vertices {
                        guard let parentValue = vertex.parent, let parent = lookup[parentValue] else { continue }
                        var path = Path()
                        path.move(to: point(parent))
                        path.addLine(to: point(vertex))
                        context.stroke(path, with: .color(.secondary.opacity(0.45)), lineWidth: 1.5)
                    }
                }

                ForEach(vertices) { vertex in
                    let color = role(vertex)
                    Text(Format.number(vertex.value))
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(color == nil ? Color.primary : Color.white)
                        .frame(width: nodeSize, height: nodeSize)
                        .background {
                            Circle().fill(color.map { AnyShapeStyle($0.gradient) }
                                          ?? AnyShapeStyle(Color.cardBackground))
                        }
                        .overlay {
                            Circle().strokeBorder(color ?? .secondary.opacity(0.5), lineWidth: 1.5)
                        }
                        .position(point(vertex))
                }
            }
            .frame(width: max(width, 1), height: height)
        }
        .frame(height: height)
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
    NavigationStack { Lab7View() }
        .environment(StatsStore())
}
