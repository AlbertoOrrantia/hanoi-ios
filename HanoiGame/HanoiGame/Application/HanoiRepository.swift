//
//  HanoiRepository.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 23/08/25.
//

import Foundation

//JSON sent to the backend
struct SolveRequest: Encodable {
    let diskCount: Int
    let labels: [String: String] = [
        "from": "A",
        "aux": "B",
        "to": "C"
    ]
    
    private enum CodingKeys: String, CodingKey {
        case diskCount = "n"
        case labels
    }
}

//JSON recieved from Backend
struct SolveResponse: Decodable {
    struct MoveDTO: Decodable {
        let disk: Int
        let from: String
        let to: String
    }
    
    let diskCount: Int  // n
    let moveCount: UInt64
    let moves: [MoveDTO]? // omitted for large n
    let movesOmitted: Bool
    let elapsedMikiseconds: Double
    
    private enum CodingKeys: String, CodingKey {
        case diskCount = "n"
        case moveCount = "count"
        case moves
        case movesOmitted
        case elapsedMikiseconds = "elapsed_ms"
    }
}

// ViewModels will depende on this protocol
protocol HanoiRepository {
    func solve(for diskCount: Int) async throws -> SolveResponse
}
