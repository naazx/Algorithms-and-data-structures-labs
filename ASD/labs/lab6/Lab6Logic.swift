//
//  Lab6Logic.swift
//  ASD
//
//  Created by Nazar Dydyn on 21.10.2026.
//

import Foundation

class Node {
    var value: Double
    var next: Node?
    
    init(value: Double) {
        self.value = value
    }
}

class Queue {
    var count: Int = 0
    
    var head: Node?
    var tail: Node?
    
    func enqueue(_ value: Double) {
        let node = Node(value: value)
        
        if isEmpty() {
            head = node
            tail = node
        } else {
            tail!.next = node
            tail = node
        }
        
        count += 1
    }
    
    func dequeue() -> Double? {
        guard let currentNode = head else {
            return nil
        }
        
        head = currentNode.next
        
        if head == nil {
            tail = nil
        }
        
        count -= 1
        return currentNode.value
    }

    
    func isEmpty() -> Bool {
        count <= 0
    }

    // MARK: - Обхід без втрати вмісту

    func forEach(_ body: (Double) -> Void) {
        let n = count
        for _ in 0..<n {
            let value = dequeue()!
            body(value)
            enqueue(value)
        }
    }

    // MARK: - Додавання без повторів

    func contains(_ value: Double) -> Bool {
        var found = false
        forEach { if $0 == value { found = true } }
        return found
    }

    @discardableResult
    func enqueueUnique(_ value: Double) -> Bool {
        if contains(value) {
            return false
        }
        enqueue(value)
        return true
    }

    // MARK: - Характеристики

    func element(at index: Int) -> Double? {
        guard index >= 0 && index < count else {
            return nil
        }
        var result: Double?
        var i = 0
        forEach { value in
            if i == index {
                result = value
            }
            i += 1
        }
        return result
    }

    func minMax() -> (min: Double, max: Double)? {
        guard let first = head?.value else {
            return nil
        }
        var minValue = first
        var maxValue = first
        forEach { value in
            if value < minValue { minValue = value }
            if value > maxValue { maxValue = value }
        }
        return (minValue, maxValue)
    }

    func thirdFromStart() -> Double? {
        element(at: 2)
    }

    func secondFromEnd() -> Double? {
        element(at: count - 2)
    }

    func beforeMin() -> Double? {
        guard let extremes = minMax(), let index = position(of: extremes.min) else {
            return nil
        }
        return element(at: index - 2)
    }

    func afterMax() -> Double? {
        guard let extremes = minMax(), let index = position(of: extremes.max) else {
            return nil
        }
        return element(at: index)
    }

    // Позиція рахується з 1; nil, якщо елемента немає
    func position(of target: Double) -> Int? {
        var result: Int?
        var i = 1
        forEach { value in
            if result == nil && value == target {
                result = i
            }
            i += 1
        }
        return result
    }

    // MARK: - Об'єднання

    func merged(with other: Queue) -> Queue {
        let result = Queue()
        forEach { result.enqueue($0) }
        other.forEach { result.enqueue($0) }
        return result
    }

    // MARK: - Виведення

    func description() -> String {
        if isEmpty() {
            return "(порожня черга)"
        }
        var text = ""
        forEach { value in
            text += text.isEmpty ? "\(value)" : " → \(value)"
        }
        return text
    }
}
