//
//  BoardViewModel.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 25/08/25.
//

import Foundation
import Observation

// Hold board state && player moves

@Observable
final class BoardViewModel {
    private(set) var rods: [Rod: [Int]] = [.A: [], .B: [], .C: []]
    private(set) var isPlaying = false
    private(set) var currentIndex = 0
    var speed: Double = 1.0 //Set for seconds per move
    
    //Solution for n<=20
    private var queued: [SolveResponse.MoveDTO] = []
    private var playTask: Task<Void, Never>?
    
    //UI Flags
    var hasQueue:Bool { !queued.isEmpty } //True if there are moves
    var isAtStart: Bool { currentIndex == 0 }
    var isAtEnd: Bool { currentIndex >= queued.count } //past las move
    
    //Progress
    var progressText: String {
        guard hasQueue else { return "0/0" }
        return "\(currentIndex)/\(queued.count)"
    }
    
    
    //MARK: Setup
    func reset(diskCount n: Int) {
        rods[.A] = Array((1...n).reversed()) //Biggest at bottom
        rods[.B] = []
        rods[.C] = []
        currentIndex = 0
        stop()
    }
    
    func load(diskCount n: Int, moves: [SolveResponse.MoveDTO]) {
        reset(diskCount: n)
        queued = moves
    }
    
    //Reflect a new disk count on board before we fecch moves
    func setDiskCountWithoutMoves(_ n: Int) {
        queued = []
        reset(diskCount: n)
    }
    
    //MARK: Player Controles
    
    func play() {
        guard !isPlaying, hasQueue, !isAtEnd else { return }
        isPlaying = true
        playTask = Task { [weak self] in
            guard let self else { return }
            while self.isPlaying, self.currentIndex < self.queued.count {
                await self.applyNext()
                try? await Task.sleep(nanoseconds: UInt64((max(0.1, self.speed) * 1_000_000_000)))
            }
            await MainActor.run { self.isPlaying = false }
        }
    }
    
    func pause() {
        isPlaying = false
        playTask?.cancel()
        playTask = nil
    }
    
    func stop() { pause() }
    
    //Step Controls
    @MainActor
    func stepForward() {
        guard hasQueue, !isAtEnd else { return }
        apply(move: queued[currentIndex])
        currentIndex += 1
    }
    
    @MainActor
    func stepBackward() {
        guard hasQueue, !isAtStart else { return }
        let last = queued[currentIndex - 1]
        //Undo by reversing from & to
        let undo = SolveResponse.MoveDTO(disk: last.disk, from: last.to, to: last.from)
        apply(move: undo)
        currentIndex -= 1
    }
    
    //Simplified ApplyNext by delegating to Apply
    @MainActor
    private func applyNext() async {
        guard hasQueue, !isAtEnd else { return }
        apply(move: queued[currentIndex])
        currentIndex += 1
    }
    
    @MainActor
    private func apply(move: SolveResponse.MoveDTO)  {
        guard
                   let fromRod = Rod(rawValue: move.from),
                   let toRod   = Rod(rawValue: move.to),
                   var from    = rods[fromRod],
                   var to      = rods[toRod]
               else { return }
               
               // Pop from
               guard let disk = from.popLast() else { return }
               
               // Rule validation, cant stack bigger one on top of smaller
               if let top = to.last, top < disk { return }
               to.append(disk)
               rods[fromRod] = from
               rods[toRod] = to
    }

}
