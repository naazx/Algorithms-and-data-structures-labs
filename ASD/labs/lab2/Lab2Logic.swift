//
//  Lab2Logic.swift
//  ASD
//
//  Created by Nazar Dydyn on 23.09.2026.
//

import Foundation

struct Student {
    let name: String
    let average: Double
}

let ukrainianLocale = Locale(identifier: "uk_UA")

func isBeforeOrEqual(_ a: String, _ b: String) -> Bool {
    a.compare(b, locale: ukrainianLocale) != .orderedDescending
}

func quickSort(_ array: inout [Student], index start: Int, index end: Int) {
    if end <= start {
        return
    }

    let pivot = partition(&array, index: start, index: end)
    quickSort(&array, index: start, index: pivot - 1)
    quickSort(&array, index: pivot + 1, index: end)
}

func partition(_ array: inout [Student], index start: Int, index end: Int) -> Int {
    let pivot = array[end].name
    var i = start - 1

    for j in start..<end {
        if isBeforeOrEqual(array[j].name, pivot) {
            i += 1
            array.swapAt(i, j)
        }
    }

    i += 1
    array.swapAt(i, end)

    return i
}

func isSorted(_ array: [Student]) -> Bool {
    guard array.count > 1 else { return true }

    for i in 0..<(array.count - 1) {
        if !isBeforeOrEqual(array[i].name, array[i + 1].name) {
            return false
        }
    }
    return true
}

func studentsAbove4(_ students: [Student]) -> [Student] {
    students.filter { $0.average > 4 }
}

func generateStudents(count: Int) -> [Student] {
    let surnames = [
        "Антоненко", "Бондар", "Василенко", "Гнатюк", "Ґудзь", "Дорошенко",
        "Єфименко", "Жук", "Зінченко", "Іваненко", "Ковальчук", "Литвин",
        "Мельник", "Онищенко", "Петренко", "Ткачук", "Шевчук", "Яремко"
    ]
    let firstNames = [
        "Андрій", "Богдан", "Віра", "Галина", "Дмитро", "Олена",
        "Ігор", "Марта", "Назар", "Оксана", "Роман", "Софія"
    ]

    return (0..<count).map { _ in
        Student(
            name: "\(surnames.randomElement()!) \(firstNames.randomElement()!)",
            average: (Double.random(in: 2...5) * 10).rounded() / 10
        )
    }
}
