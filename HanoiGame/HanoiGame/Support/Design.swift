//
//  Design.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 27/08/25.
//

import SwiftUI

enum Design {
    enum Spacing {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
    }
    
    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
    }
    
    enum Fonts {
        //Semantic Names
        static let title = Font.title.bold()
        static let label = Font.callout
        static let mono = Font.callout.monospacedDigit()
        static let note = Font.caption
    }
}
