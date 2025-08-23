//
//  Enviroment.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 23/08/25.
//

import Foundation

enum Environment {
    //TO DO: Add HANOI_BASE_URL to info.plist
    static var baseURL: URL {
        guard
            let raw = Bundle.main.object(forInfoDictionaryKey: "HANOI_BASE_URL") as? String,
            let url = URL(string: raw)
                else {
            fatalError("HanoiGame: Base URL not found in Info.plist")
        }
        return url
    }
}
