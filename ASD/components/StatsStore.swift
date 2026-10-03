//
//  StatsStore.swift
//  ASD
//
//  Persisted history of lab runs used by the profile screen.
//

import Foundation
import Observation

struct LabRun: Codable, Identifiable, Hashable {
    var id = UUID()
    let lab: Int
    let date: Date
    let elements: Int
    let milliseconds: Double?
    let isSorted: Bool?
}

struct DayActivity: Identifiable {
    let day: Date
    let count: Int
    var id: Date { day }
}

@Observable
final class StatsStore {
    private(set) var runs: [LabRun] = []

    private let storageKey = "stats.runs"
    private let maxStoredRuns = 1_000

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([LabRun].self, from: data) {
            runs = decoded
        }
    }

    func record(lab: Int, elements: Int, milliseconds: Double? = nil, isSorted: Bool? = nil) {
        runs.append(LabRun(lab: lab, date: .now, elements: elements,
                           milliseconds: milliseconds, isSorted: isSorted))
        if runs.count > maxStoredRuns {
            runs.removeFirst(runs.count - maxStoredRuns)
        }
        save()
    }

    func reset() {
        runs = []
        save()
    }

    private func save() {
        if let data = try? JSONEncoder().encode(runs) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    // MARK: - Derived stats

    var totalElements: Int {
        runs.reduce(0) { $0 + $1.elements }
    }

    var exploredLabs: Int {
        Set(runs.map(\.lab)).count
    }

    /// Share of runs whose result was verified as sorted, or nil when nothing was checked.
    var correctnessRate: Double? {
        let checked = runs.compactMap(\.isSorted)
        guard !checked.isEmpty else { return nil }
        return Double(checked.filter { $0 }.count) / Double(checked.count)
    }

    /// Consecutive days with at least one run, ending today (or yesterday).
    var streak: Int {
        let calendar = Calendar.current
        let activeDays = Set(runs.map { calendar.startOfDay(for: $0.date) })
        var day = calendar.startOfDay(for: .now)
        if !activeDays.contains(day) {
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        var count = 0
        while activeDays.contains(day) {
            count += 1
            day = calendar.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    var favoriteLab: Int? {
        Dictionary(grouping: runs, by: \.lab)
            .max { $0.value.count < $1.value.count }?
            .key
    }

    func runCount(for lab: Int) -> Int {
        runs.reduce(0) { $0 + ($1.lab == lab ? 1 : 0) }
    }

    func lastRun(for lab: Int) -> LabRun? {
        runs.last { $0.lab == lab }
    }

    func largestRun(for lab: Int) -> LabRun? {
        runs.filter { $0.lab == lab }.max { $0.elements < $1.elements }
    }

    func dailyActivity(days: Int = 7) -> [DayActivity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let counts = Dictionary(grouping: runs) { calendar.startOfDay(for: $0.date) }
            .mapValues(\.count)

        return (0..<days).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            return DayActivity(day: day, count: counts[day] ?? 0)
        }
    }
}
