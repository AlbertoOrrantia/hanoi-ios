//
//  BoardView.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 26/08/25.
//

import SwiftUI

struct BoardView: View {
    @Bindable var viewModel: BoardViewModel

    @State private var dragging: (rod: Rod, disk: Int)? = nil
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geo in
            let topInset: CGFloat = 10
            
            let spacing: CGFloat = 16
            let colWidth    = (geo.size.width - spacing * 2) / 3.0
            let boardHeight = min(geo.size.height - 28, 400) - topInset

            HStack(alignment: .bottom, spacing: spacing) {
                column(.A, width: colWidth, height: boardHeight, spacing: spacing)
                column(.B, width: colWidth, height: boardHeight, spacing: spacing)
                column(.C, width: colWidth, height: boardHeight, spacing: spacing)
            }
            .frame(width: geo.size.width, height: boardHeight, alignment: .bottom)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.top, topInset)
            .padding(.horizontal, 0)
            .padding(.bottom, 2)
        }
    }

    //  Single rod + its stack
    private func column(_ rod: Rod, width: CGFloat, height: CGFloat, spacing: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            // Pole
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.22))
                .frame(width: 8, height: height * 0.82)

            // Base
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.22))
                .frame(width: width * 0.88, height: 10)

            VStack(spacing: 6) {
                ForEach((viewModel.rods[rod] ?? []).reversed(), id: \.self) { size in
                    // Use global max so discs keep the same width while moving between rods
                    let globalMaxInt = max(viewModel.rods.values.flatMap { $0 }.max() ?? 1, 1)
                    let maxSize = CGFloat(globalMaxInt)

                    let w = max(40, (width * 0.75) * CGFloat(size) / maxSize)
                    let isTop = (viewModel.rods[rod]?.last == size)

                    DiscView(width: w, label: "\(size)")
                        .offset(dragging?.rod == rod && dragging?.disk == size ? dragOffset : .zero)
                        .allowsHitTesting(isTop && !viewModel.isPlaying)
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            DragGesture(minimumDistance: 3)
                                .onChanged { value in
                                    guard isTop, viewModel.canPickTop(from: rod, disk: size) else { return }
                                    dragging = (rod, size)
                                    dragOffset = value.translation
                                }
                                .onEnded { value in
                                    guard dragging != nil else { return }

                                    if abs(value.translation.width) < width * 0.25 {
                                        dragging = nil
                                        dragOffset = .zero
                                        return
                                    }

                                    let order: [Rod] = [.A, .B, .C]
                                    guard let startIdx = order.firstIndex(of: rod) else {
                                        dragging = nil
                                        dragOffset = .zero
                                        return
                                    }

                                    let localX     = value.location.x
                                    let absoluteX  = localX + CGFloat(startIdx) * (width + spacing)
                                    let totalWidth = (width * 3) + (spacing * 2)
                                    let ratio      = max(0, min(1, absoluteX / totalWidth))
                                    let targetIdx  = Int((ratio * 3).clamped(to: 0...2))
                                    let target     = order[targetIdx]

                                    if target == rod {
                                        dragging = nil
                                        dragOffset = .zero
                                        return
                                    }

                                    // manual mode rule: a bigger one can’t sit on a smaller one
                                    if let top = viewModel.rods[target]?.last, top < size {
                                        UINotificationFeedbackGenerator().notificationOccurred(.error)
                                        dragging = nil
                                        dragOffset = .zero
                                        return
                                    }

                                    Task { @MainActor in
                                        _ = viewModel.tryMoveTop(from: rod, to: target, enforceRules: false)
                                    }
                                    dragging = nil
                                    dragOffset = .zero
                                }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .frame(width: width, alignment: .bottom)
            .animation(.snappy(duration: 0.25), value: viewModel.rods)
        }
        .frame(width: width, height: height, alignment: .bottom)
        .accessibilityLabel("Rod \(rod.rawValue)")
        .accessibilityHint("Hanoi Tower Rod")
    }

    private func offsetRod(from: Rod, by steps: Int) -> Rod {
        let order: [Rod] = [.A, .B, .C]
        guard let i = order.firstIndex(of: from) else { return from }
        let j = max(0, min(order.count - 1, i + steps))
        return order[j]
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

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
