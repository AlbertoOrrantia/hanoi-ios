//
//  RodState.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 23/08/25.
//

import Foundation

//Snapshot of the board represented as 3 stacks
//Convention: 'Top' is the last of the disk

struct RodState: Equatable, Sendable {
    var a: [Int]
    var b: [Int]
    var c: [Int]
    
    //If Any, convenience to read the top of the disk
    func top(of rod: Rod) -> Int? {
        switch rod {
            case .A: return a.last
            case .B: return b.last
            case .C: return c.last
        }
    }
}
