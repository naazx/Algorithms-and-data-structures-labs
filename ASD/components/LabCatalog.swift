//
//  LabCatalog.swift
//  ASD
//
//  Descriptions of every lab shown in the app.
//

import SwiftUI

struct LabInfo: Identifiable, Hashable {
    let id: Int
    let title: String
    let task: String
    var variant: Int? = nil
    var complexity: String? = nil
    let symbol: String
    let tint: Color
    var isAvailable: Bool = true
}

enum LabCatalog {
    static let all: [LabInfo] = [
        LabInfo(
            id: 1,
            title: "Сортування Шелла",
            task: "Упорядкувати елементи масиву, що розташовані між першим і останнім від'ємним числом.",
            complexity: "≈ O(n²)",
            symbol: "arrow.left.arrow.right",
            tint: .indigo
        ),
        LabInfo(
            id: 2,
            title: "Швидке сортування",
            task: "Вибрати студентів із середнім балом понад 4 та впорядкувати їх за алфавітом.",
            variant: 8,
            complexity: "O(n log n)",
            symbol: "bolt.fill",
            tint: .orange
        ),
        LabInfo(
            id: 3,
            title: "Сортування злиттям",
            task: "Сформувати масив із парних елементів масиву A та непарних елементів масиву B і впорядкувати його за зростанням.",
            variant: 10,
            complexity: "O(n log n)",
            symbol: "arrow.triangle.merge",
            tint: .teal
        ),
        LabInfo(
            id: 4,
            title: "Сортування підрахунком",
            task: "Замінити максимум кожного рядка матриці на його кубічний корінь, а рядки впорядкувати за першими елементами.",
            variant: 11,
            complexity: "O(n + k)",
            symbol: "number",
            tint: .pink
        ),
        LabInfo(
            id: 5,
            title: "Порівняння методів",
            task: "Елементи після максимального впорядкувати за спаданням чотирма методами та порівняти час їх роботи.",
            variant: 12,
            complexity: "4 алгоритми",
            symbol: "chart.xyaxis.line",
            tint: .purple
        ),
    ] + (6...10).map { id in
        LabInfo(
            id: id,
            title: "Лабораторна робота №\(id)",
            task: "Завдання з'явиться згодом.",
            symbol: "lock.fill",
            tint: .gray,
            isAvailable: false
        )
    }

    static var available: [LabInfo] { all.filter(\.isAvailable) }

    static func lab(_ id: Int) -> LabInfo {
        all.first { $0.id == id }!
    }
}
