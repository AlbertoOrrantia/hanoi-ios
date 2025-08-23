//
//  Move.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 23/08/25.
//

import Foundation

//Single legal move on the game; move 'disk' from 'position' to 'position'
struct Move: Equatable, Sendable {
    let disk: Int
    let from: Rod
    let to: Rod
}
