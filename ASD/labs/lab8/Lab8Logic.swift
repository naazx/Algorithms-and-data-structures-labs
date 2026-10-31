//
//  Lab8Logic.swift
//  ASD
//
//  Created by Nazar Dydyn on 31.10.2026.
//

import Foundation

enum StepOutcome {
    case found
    case goLeft
    case goRight
}

struct SearchStep {
    let low: Int
    let high: Int
    let middle: Int
    let value: Int
    let outcome: StepOutcome
}

struct SearchResult {
    let position: Int?
    let comparisons: Int
    let steps: [SearchStep]
}

struct ComplexityRow {
    let count: Int
    let average: Double
    let worst: Int
    let bound: Int
}

func generateSortedArray(count: Int) -> [Int] {
    var result: [Int] = []
    var value = Int.random(in: -50...50)
    
    for _ in 0..<count {
        result.append(value)
        value += Int.random(in: 1...3)
    }
    return result
}

func binarySearch(_ array: [Int], target: Int) -> SearchResult {
    var low = 0
    var high = array.count - 1
    var comparisons = 0
    var steps: [SearchStep] = []
    
    while low <= high {
        let middle = (low + high) / 2
        let buffer = array[middle]
        comparisons += 1
        
        if buffer == target {
            steps.append(SearchStep(low: low + 1, high: high + 1, middle: middle + 1, value: buffer, outcome: .found))
            return SearchResult(position: middle + 1, comparisons: comparisons, steps: steps)
        }
        
        if buffer > target {
            steps.append(SearchStep(low: low + 1, high: high + 1, middle: middle + 1, value: buffer, outcome: .goLeft))
            high = middle - 1
        } else {
            steps.append(SearchStep(low: low + 1, high: high + 1, middle: middle + 1, value: buffer, outcome: .goRight))
            low = middle + 1
        }
    }
    
    return SearchResult(position: nil, comparisons: comparisons, steps: steps)
}

func targetValue(for array: [Int]) -> Int? {
    guard let minimum = array.first else {
        return nil
    }
    return minimum + 10
}

func comparisonBound(count: Int) -> Int {
    guard count > 0 else {
        return 0
    }
    return Int.bitWidth - count.leadingZeroBitCount
}

func complexityRow(count: Int) -> ComplexityRow {
    let array = generateSortedArray(count: count)
    
    var total = 0
    var worst = 0
    for element in array {
        let comparisons = binarySearch(array, target: element).comparisons
        total += comparisons
        worst = max(worst, comparisons)
    }
    
    return ComplexityRow(
        count: count,
        average: Double(total) / Double(count),
        worst: worst,
        bound: comparisonBound(count: count)
    )
}
