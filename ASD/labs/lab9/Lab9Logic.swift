//
//  Lab9Logic.swift
//  ASD
//
//  Created by Nazar Dydyn on 10.11.2026.
//

import Foundation

struct WordSpan {
    let text: String
    let start: Int
    let end: Int

    var length: Int { end - start }
}

struct SwapResult {
    let words: [WordSpan]
    let longestIndex: Int
    let shortestIndex: Int
    let swappedText: String
    let pattern: String

    var longest: String { words[longestIndex].text }
    var shortest: String { words[shortestIndex].text }
}

struct SearchOutcome {
    let positions: [Int]
    let comparisons: Int
}

struct BenchmarkRow {
    let size: Int
    let kmpMilliseconds: Double
    let kmpComparisons: Int
    let naiveMilliseconds: Double
    let naiveComparisons: Int
}

private func isWordCharacter(_ character: Character) -> Bool {
    character.isLetter || character.isNumber || character == "'" || character == "’"
}

func extractWords(from text: String) -> [WordSpan] {
    let characters = Array(text)
    var words: [WordSpan] = []
    var start: Int? = nil

    for index in 0...characters.count {
        let isWord = index < characters.count && isWordCharacter(characters[index])

        if isWord {
            if start == nil {
                start = index
            }
        } else if let begin = start {
            words.append(WordSpan(text: String(characters[begin..<index]), start: begin, end: index))
            start = nil
        }
    }
    return words
}

func swapLongestAndShortest(in text: String) -> SwapResult? {
    let words = extractWords(from: text)
    guard words.count >= 2 else {
        return nil
    }

    var longestIndex = 0
    var shortestIndex = 0
    for index in words.indices {
        if words[index].length > words[longestIndex].length {
            longestIndex = index
        }
        if words[index].length < words[shortestIndex].length {
            shortestIndex = index
        }
    }
    guard words[longestIndex].length > words[shortestIndex].length else {
        return nil
    }

    let characters = Array(text)
    var swapped = ""
    var cursor = 0

    for index in words.indices {
        let word = words[index]
        swapped += String(characters[cursor..<word.start])

        if index == longestIndex {
            swapped += words[shortestIndex].text
        } else if index == shortestIndex {
            swapped += words[longestIndex].text
        } else {
            swapped += word.text
        }
        cursor = word.end
    }
    swapped += String(characters[cursor...])

    return SwapResult(
        words: words,
        longestIndex: longestIndex,
        shortestIndex: shortestIndex,
        swappedText: swapped,
        pattern: words[longestIndex].text + words[shortestIndex].text
    )
}

func prefixFunction<T: Equatable>(_ pattern: [T]) -> [Int] {
    var prefix = [Int](repeating: 0, count: pattern.count)
    guard pattern.count > 1 else {
        return prefix
    }

    var length = 0
    for index in 1..<pattern.count {
        while length > 0 && pattern[index] != pattern[length] {
            length = prefix[length - 1]
        }
        if pattern[index] == pattern[length] {
            length += 1
        }
        prefix[index] = length
    }
    return prefix
}

func kmpSearch<T: Equatable>(text: [T], pattern: [T], prefix: [Int]) -> SearchOutcome {
    guard !pattern.isEmpty, text.count >= pattern.count else {
        return SearchOutcome(positions: [], comparisons: 0)
    }

    var positions: [Int] = []
    var comparisons = 0
    var matched = 0

    for index in text.indices {
        while true {
            comparisons += 1
            if text[index] == pattern[matched] {
                matched += 1
                break
            }
            if matched == 0 {
                break
            }
            matched = prefix[matched - 1]
        }

        if matched == pattern.count {
            positions.append(index - matched + 1)
            matched = prefix[matched - 1]
        }
    }
    return SearchOutcome(positions: positions, comparisons: comparisons)
}

func naiveSearch<T: Equatable>(text: [T], pattern: [T]) -> SearchOutcome {
    guard !pattern.isEmpty, text.count >= pattern.count else {
        return SearchOutcome(positions: [], comparisons: 0)
    }

    var positions: [Int] = []
    var comparisons = 0

    for start in 0...(text.count - pattern.count) {
        var offset = 0
        while offset < pattern.count {
            comparisons += 1
            if text[start + offset] != pattern[offset] {
                break
            }
            offset += 1
        }
        if offset == pattern.count {
            positions.append(start)
        }
    }
    return SearchOutcome(positions: positions, comparisons: comparisons)
}

func measure<T>(_ work: () -> T) -> (value: T, milliseconds: Double) {
    let clock = ContinuousClock()
    let start = clock.now
    let value = work()
    let elapsed = start.duration(to: clock.now)
    let milliseconds = Double(elapsed.components.seconds) * 1_000 + Double(elapsed.components.attoseconds) / 1e15
    return (value, milliseconds)
}

func benchmarkRow(size: Int, patternLength: Int) -> BenchmarkRow {
    let text = [UInt8](repeating: 97, count: size)
    let pattern = [UInt8](repeating: 97, count: patternLength - 1) + [98]
    let prefix = prefixFunction(pattern)

    let kmpRun = measure { kmpSearch(text: text, pattern: pattern, prefix: prefix) }
    let naiveRun = measure { naiveSearch(text: text, pattern: pattern) }

    return BenchmarkRow(
        size: size,
        kmpMilliseconds: kmpRun.milliseconds,
        kmpComparisons: kmpRun.value.comparisons,
        naiveMilliseconds: naiveRun.milliseconds,
        naiveComparisons: naiveRun.value.comparisons
    )
}
