//
//  Lab3Logic.swift
//  ASD
//
//  Created by Nazar Dydyn on 30.09.2026.
//

import Foundation

func generateArray(count: Int) -> [Int] {
    (0..<count).map { _ in Int.random(in: -1000...1000) }
}

func formArray(_ a: [Int], _ b: [Int]) -> [Int] {
    a.filter { $0 % 2 == 0 } + b.filter { $0 % 2 != 0 }
}

func mergeSort(_ array: [Int]) -> [Int] {
    guard array.count > 1 else { return array }

    let mid = array.count / 2
    let left = mergeSort(Array(array[..<mid]))
    let right = mergeSort(Array(array[mid...]))

    return merge(left, right)
}

func merge(_ left: [Int], _ right: [Int]) -> [Int] {
    var result: [Int] = []
    result.reserveCapacity(left.count + right.count)
    var i = 0
    var j = 0

    while i < left.count && j < right.count {
        if left[i] <= right[j] {
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

func isSorted(_ array: [Int]) -> Bool {
    guard array.count > 1 else { return true }

    for i in 0..<(array.count - 1) {
        if array[i] > array[i + 1] {
            return false
        }
    }
    return true
}
