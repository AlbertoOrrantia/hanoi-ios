//
//  HanoiRules.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 23/08/25.
//

import Foundation

// Small helper to enconde the game rules
// Maintain here to avoid View/ViewModel burden
enum HanoiRules {
    // Return true when we are moving the 'top' disk of the source rod and we dont place a larger disk on top of a smaller
    static func isLegal(_ move: Move, on state: RodState) -> Bool {
        guard state.top(of: move.from) == move.disk else { return  false }
        
        if let destinationTop = state.top(of: move.to) {
            return move.disk < destinationTop
        }
        return true
    }
        
    // Minimal number of moves to solve (2**n-1)
    static func minimalCount(forDiskCount diskCount: Int) -> UInt64 {
        guard diskCount  > 0 else { return 0 }
        return (1 &<< diskCount) &- 1 // 2**n - 1
    }
}
