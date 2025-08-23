//
//  NetworkHanoiRepository.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 23/08/25.
//

import Foundation

// Repository that talks with FASTAPI using URLSessions
final class NetworkHanoiRepository: HanoiRepository {
    
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: URL = Environment.baseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func solve(for diskCount: Int) async throws -> SolveResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("solve"))
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(SolveRequest(diskCount: diskCount))
        
        //Simple Happy Path, errors surface to the ViewModel
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(SolveResponse.self, from: data)
    }
}
