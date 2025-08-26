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
    
    //MARK: Player Controles
    
    func play() {
        guard !isPlaying, !queued.isEmpty else { return }
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
    
    
    
    @MainActor
    private func applyNext() async {
        guard currentIndex < queued.count else { return }
        let m = queued[currentIndex]
        currentIndex += 1
        
        guard let from = Rod(rawValue: m.from), let to = Rod(rawValue: m.to) else { return }
        
        //Pop from
        guard var fromStack = rods[from], var toStack = rods[to] else { return }
        guard let disk = fromStack.popLast() else { return }
        
        //Rule validation, cant stack bigger one on top of smaller
        if let top = toStack.last, top < disk { return }
        toStack.append(disk)
        rods[from] = fromStack
        rods[to] = toStack
    }
}
