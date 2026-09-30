//
//  Lab5Logic.swift
//  ASD
//
//  Created by Nazar Dydyn on 30.09.2026.
//

import Foundation

nonisolated struct TimeLimit {
    let deadline: ContinuousClock.Instant

    init(seconds: Double) {
        deadline = ContinuousClock.now + .seconds(seconds)
    }

    var isExceeded: Bool {
        ContinuousClock.now >= deadline
    }
}

nonisolated struct BenchmarkOutcome {
    let milliseconds: Double?
    let isSorted: Bool
}

nonisolated func generateBenchmarkArray(count: Int) -> [Double] {
    var array = (0..<count).map { _ in
        Double(Int.random(in: -1_000_000...1_000_000)) / 10
    }
    if let maxIndex = array.indices.max(by: { array[$0] < array[$1] }) {
        array.swapAt(0, maxIndex)
    }
    return array
}

nonisolated func elementsAfterMax(_ array: [Double]) -> [Double] {
    guard let maxValue = array.max(),
          let maxIndex = array.firstIndex(of: maxValue) else {
        return []
    }
    return Array(array[(maxIndex + 1)...])
}

nonisolated func shellSortDescending(_ array: inout [Double], limit: TimeLimit) -> Bool {
    let n = array.count
    var d = n / 2

    while d >= 1 {
        for i in d..<n {
            if i & 65535 == 0 && limit.isExceeded {
                return false
            }
            let temp = array[i]
            var j = i

            while j >= d && array[j - d] < temp {
                array[j] = array[j - d]
                j -= d
            }
            array[j] = temp
        }
        d /= 2
    }
    return true
}

nonisolated func quickSortDescending(_ array: inout [Double], from start: Int, to end: Int) {
    if end <= start {
        return
    }

    let pivot = partitionDescending(&array, from: start, to: end)
    quickSortDescending(&array, from: start, to: pivot - 1)
    quickSortDescending(&array, from: pivot + 1, to: end)
}

nonisolated func partitionDescending(_ array: inout [Double], from start: Int, to end: Int) -> Int {
    let pivot = array[end]
    var i = start - 1

    for j in start..<end {
        if array[j] >= pivot {
            i += 1
            array.swapAt(i, j)
        }
    }

    i += 1
    array.swapAt(i, end)

    return i
}

nonisolated func mergeSortDescending(_ array: [Double]) -> [Double] {
    guard array.count > 1 else { return array }

    let mid = array.count / 2
    let left = mergeSortDescending(Array(array[..<mid]))
    let right = mergeSortDescending(Array(array[mid...]))

    return mergeDescending(left, right)
}

nonisolated func mergeDescending(_ left: [Double], _ right: [Double]) -> [Double] {
    var result: [Double] = []
    result.reserveCapacity(left.count + right.count)
    var i = 0
    var j = 0

    while i < left.count && j < right.count {
        if left[i] >= right[j] {
            result.append(left[i])
            i += 1
        } else {
            result.append(right[j])
            j += 1
        }
    }

    result.append(contentsOf: left[i...])
    result.append(contentsOf: right[j...])

    return result
}

nonisolated func countingSortDescending(_ array: inout [Double]) {
    guard array.count > 1 else { return }

    let keys = array.map { Int(($0 * 10).rounded()) }
    let minKey = keys.min()!
    let maxKey = keys.max()!

    var counts = [Int](repeating: 0, count: maxKey - minKey + 1)
    for key in keys {
        counts[maxKey - key] += 1
    }

    for k in 1..<counts.count {
        counts[k] += counts[k - 1]
    }

    var output = array
    for i in stride(from: array.count - 1, through: 0, by: -1) {
        let index = maxKey - keys[i]
        counts[index] -= 1
        output[counts[index]] = array[i]
    }

    array = output
}

nonisolated func isSortedDescending(_ array: [Double]) -> Bool {
    guard array.count > 1 else { return true }

    for i in 0..<(array.count - 1) {
        if array[i] < array[i + 1] {
            return false
        }
    }
    return true
}

nonisolated func runBenchmarkSort(method: Int, data: inout [Double], limit: TimeLimit) -> Bool {
    switch method {
    case 0:
        return shellSortDescending(&data, limit: limit)
    case 1:
        quickSortDescending(&data, from: 0, to: data.count - 1)
        return true
    case 2:
        data = mergeSortDescending(data)
        return true
    default:
        countingSortDescending(&data)
        return true
    }
}

nonisolated func measureSort(method: Int, source: [Double], limitSeconds: Double) -> BenchmarkOutcome {
    var work = source.map { $0 }
    let limit = TimeLimit(seconds: limitSeconds)

    let clock = ContinuousClock()
    let start = clock.now

    let finished = runBenchmarkSort(method: method, data: &work, limit: limit)

    let elapsed = clock.now - start

    guard finished else {
        return BenchmarkOutcome(milliseconds: nil, isSorted: true)
    }

    let ms = Double(elapsed.components.seconds) * 1_000
           + Double(elapsed.components.attoseconds) / 1e15
    return BenchmarkOutcome(milliseconds: ms, isSorted: isSortedDescending(work))
}
