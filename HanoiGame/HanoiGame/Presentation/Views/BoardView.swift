//
//  BoardView.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 26/08/25.
//

import SwiftUI

struct BoardView: View {
    @Bindable var viewModel: BoardViewModel

    var body: some View {
        GeometryReader { geo in
            let colWidth = geo.size.width / 3.0
            HStack(alignment: .bottom, spacing: 16) {
                column(.A, width: colWidth)
                column(.B, width: colWidth)
                column(.C, width: colWidth)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(12)
        }
    }

    //  Single rod + its stack
    private func column(_ rod: Rod, width: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            // Pole
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.22))
                .frame(width: 8, height: 220)
                .offset(y: -10)

            // Base
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.25))
                .frame(width: width * 0.9, height: 10)
                .offset(y: 5)

            VStack(spacing: 6) {
                ForEach((viewModel.rods[rod] ?? []).reversed(), id: \.self) { size in
                    // width grows with size,1 is minimal
                    let w = max(40, (width * 0.75) * CGFloat(size) / CGFloat(max(1, (viewModel.rods[.A]?.max() ?? 1))))
                    DiscView(width: w, label: "\(size)")
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .frame(width: width, alignment: .bottom)
            .animation(.snappy(duration: 0.25), value: viewModel.rods)
        }
        .frame(width: width, height: 260, alignment: .bottom)
        .accessibilityLabel("Rod \(rod.rawValue)")
    }
}

private struct DiscView: View {
    let width: CGFloat
    let label: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Design.Radius.sm)
                .fill(
                    LinearGradient(colors: [.blue.opacity(0.25), .blue.opacity(0.18)], startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Design.Radius.sm)
                        .stroke(.blue.opacity(0.6), lineWidth: 1)
                )
                .frame(width: width, height: 22)

            Text(label)
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.primary)
        }
        .shadow(radius: 1, y: 1)
    }
}
