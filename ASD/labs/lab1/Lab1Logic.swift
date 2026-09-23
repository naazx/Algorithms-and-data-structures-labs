//
//  Lab1Logic.swift
//  ASD
//
//  Created by Nazar Dydyn on 18.09.2026.
//

import Foundation

func shellSort(_ array: inout [Double]) {
    let n = array.count
    var d = n / 2

    while d >= 1 {
        for i in d..<n {
            let temp = array[i]
            var j = i

            while j >= d && array[j - d] > temp {
                array[j] = array[j - d]
                j -= d
            }
            array[j] = temp
        }
        d /= 2
    }
}

func findNegativeRange(in array: [Double]) -> (first: Int, last: Int)? {
    guard let first = array.firstIndex(where: { $0 < 0 }),
          let last = array.lastIndex(where: { $0 < 0 }) else {
        return nil
    }
    return (first, last)
}

func sortBetweenNegatives(_ array: inout [Double]) {
    guard let range = findNegativeRange(in: array) else {
        return
    }
    guard range.last - range.first > 1 else {
        return
    }

    var sub = Array(array[(range.first + 1)..<range.last])
    shellSort(&sub)

    for (offset, value) in sub.enumerated() {
        array[range.first + 1 + offset] = value
    }
}
