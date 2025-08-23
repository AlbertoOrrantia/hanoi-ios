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
            
            if let moves = response.moves {
                steps = moves.map { move in
                    "Take disk \(move.disk) from rod \(move.from) to rod \(move.to)"
                }
            } else {
                steps = ["Moves omitted (\(response.moves) total)"]
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
