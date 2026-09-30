//
//  Lab4Logic.swift
//  ASD
//
//  Created by Nazar Dydyn on 30.09.2026.
//

import Foundation

func generateMatrix(rows: Int, cols: Int) -> [[Double]] {
    (0..<rows).map { _ in
        (0..<cols).map { _ in Double(Int.random(in: -1000...1000)) / 10 }
    }
}

func replaceMaxWithCbrt(_ matrix: [[Double]]) -> [[Double]] {
    matrix.map { row in
        guard let maxValue = row.max() else { return row }
        let replacement = (cbrt(maxValue) * 10).rounded() / 10
        return row.map { $0 == maxValue ? replacement : $0 }
    }
}

func sortKey(_ value: Double) -> Int {
    Int((value * 10).rounded())
}

func countingSortRows(_ matrix: [[Double]]) -> [[Double]] {
    guard matrix.count > 1 else { return matrix }

    let keys = matrix.map { sortKey($0[0]) }
    let minKey = keys.min()!
    let maxKey = keys.max()!

    var counts = [Int](repeating: 0, count: maxKey - minKey + 1)
    for key in keys {
        counts[key - minKey] += 1
    }

    for k in 1..<counts.count {
        counts[k] += counts[k - 1]
    }

    var output = matrix
    for i in stride(from: matrix.count - 1, through: 0, by: -1) {
        let index = keys[i] - minKey
        counts[index] -= 1
        output[counts[index]] = matrix[i]
    }

    return output
}

func isSorted(_ matrix: [[Double]]) -> Bool {
    guard matrix.count > 1 else { return true }

    for i in 0..<(matrix.count - 1) {
        if matrix[i][0] > matrix[i + 1][0] {
            return false
        }
    }
    return true
}
