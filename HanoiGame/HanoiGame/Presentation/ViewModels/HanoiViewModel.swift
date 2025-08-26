//
//  HanoiViewModel.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 23/08/25.
//

import Foundation
import Observation

@Observable
final class HanoiViewModel {
    
    //MARK: - Inputs
    
    // Number of disks selected by de user
    var diskCount: Int = 6
    var steps: [String] = []
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let repository: HanoiRepository
    
    init(repository: HanoiRepository = NetworkHanoiRepository()) {
        self.repository = repository
    }
    
    //MARK: - Intents
    
    // Fetches solution form backend, formats steps
    @MainActor
    func fetchSolution() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let response = try await repository.solve(for: diskCount)
            
            let totalMoves: UInt64 = response.moveCount != 0 ? response.moveCount : HanoiRules.minimalCount(forDiskCount: diskCount)
            
            if let moves = response.moves {
                steps = moves.map { move in
                    "Take disk \(move.disk) from rod \(move.from) to rod \(move.to)"
                }
                steps.append(contentsOf: ["Total moves: \(totalMoves)"])
                steps.append(contentsOf: ["Total time elapsed: \(String(format: "%.2f", response.elapsedMilliseconds)) ms"])
            } else {
                steps = ["Moves omitted, total moves: \(totalMoves)",
                         "Time Elapsed: \(String(format: "%.2f", response.elapsedMilliseconds)) ms"]
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    //Clear UI
    @MainActor
    func clear() {
        steps.removeAll()
        errorMessage = nil
    }
    
}
