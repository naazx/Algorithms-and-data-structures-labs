//
//  Lab7Logic.swift
//  ASD
//
//  Created by Nazar Dydyn on 21.10.2026.
//

import Foundation

class TreeNode {
    var value: Double
    var left: TreeNode?
    var right: TreeNode?
    
    init(value: Double) {
        self.value = value
    }
}

class BinarySearchTree {
    var root: TreeNode?
    var count: Int = 0
    
    func isEmpty() -> Bool {
        root == nil
    }
    
    @discardableResult
    func insert(_ value: Double) -> Bool {
        let node = TreeNode(value: value)
        
        guard var current = root else {
            root = node
            count = 1
            return true
        }
        
        while true {
            if value == current.value {
                return false
            }
            
            if value < current.value {
                if let next = current.left {
                    current = next
                } else {
                    current.left = node
                    break
                }
            } else {
                if let next = current.right {
                    current = next
                } else {
                    current.right = node
                    break
                }
            }
        }
        
        count += 1
        return true
    }
    
    func preorder(_ visit: (Double) -> Void) {
        preorder(root, visit)
    }
    
    private func preorder(_ node: TreeNode?, _ visit: (Double) -> Void) {
        guard let node else {
            return
        }
        visit(node.value)
        preorder(node.left, visit)
        preorder(node.right, visit)
    }
    
    private func find(_ value: Double) -> (node: TreeNode, parent: TreeNode?)? {
        var current = root
        var parent: TreeNode?
        
        while let node = current {
            if value == node.value {
                return (node, parent)
            }
            parent = node
            current = value < node.value ? node.left : node.right
        }
        return nil
    }
    
    func contains(_ value: Double) -> Bool {
        find(value) != nil
    }
    
    func relatives(of value: Double) -> (parent: Double?, left: Double?, right: Double?)? {
        guard let found = find(value) else {
            return nil
        }
        return (found.parent?.value, found.node.left?.value, found.node.right?.value)
    }
    
    func secondLargest() -> Double? {
        guard var current = root else {
            return nil
        }
        
        var parent: TreeNode?
        while let next = current.right {
            parent = current
            current = next
        }
        
        if var candidate = current.left {
            while let next = candidate.right {
                candidate = next
            }
            return candidate.value
        }
        return parent?.value
    }
}
