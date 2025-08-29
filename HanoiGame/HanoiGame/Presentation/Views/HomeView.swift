//
//  HomeView.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 22/08/25.
//

import SwiftUI
import UIKit

struct HomeView: View {
    
    @State private var viewModel = HanoiViewModel()
    @State private var boardVM = BoardViewModel()
    @State private var showError: Bool = false
    
    @AppStorage("hanoi_diskCount") private var savedDisks: Int = 4
    @AppStorage("hanoi_speed")     private var savedSpeed: Double = 1.0
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                leftpanel
                    .frame(width: min(max(geo.size.width * 0.26, 240), 300))
                    .padding(.leading, 16)
                
                rightpanel(geo: geo)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: max(420, geo.size.height - 40))
                    .padding(.trailing, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showError = (newValue != nil)
                if newValue != nil {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }
            }
            .onAppear {
                viewModel.diskCount = savedDisks
                boardVM.speed = savedSpeed
            }
            .onChange(of: viewModel.diskCount) { _, new in
                savedDisks = new
            }
            .onChange(of: boardVM.speed) { _, new in
                savedSpeed = new
            }
            .alert("Network Error", isPresented: $showError) {
                Button("Retry") {
                    Task { await viewModel.fetchSolution() }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }
    
    //MARK: - Panels
    
    private var leftpanel: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            
            Text("Hanoi Tower")
                .font(Design.Fonts.title)
            
            //Disk Selector
            Stepper("Disks: \(viewModel.diskCount)",
                    value: $viewModel.diskCount,
                    in: 1...64)
            .font(Design.Fonts.label)
            
            HStack(spacing: 12.0) {
                Button("Fetch Solution") {
                    Task {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred() // tiny delight on tap
                        await viewModel.fetchSolution()

                        if let response = viewModel.lastResponse, viewModel.errorMessage == nil {
                            if let moves = response.moves {
                                await MainActor.run {
                                    boardVM.load(diskCount: response.diskCount, moves: moves)
                                }
                            } else {
                                await MainActor.run {
                                    boardVM.setDiskCountWithoutMoves(response.diskCount)
                                }
                            }
                            UINotificationFeedbackGenerator().notificationOccurred(.success) // success haptic
                        }

                        // quick sanity print
                        if let c = viewModel.lastResponse?.moves?.count {
                            print("Loaded \(c) moves into board")
                        } else {
                            print("Moves omitted or response missing")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                
                Button("Clear") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred() // tiny delight on clear
                    print(Environment.baseURL)
                    viewModel.clear()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                
                if !viewModel.steps.isEmpty {
                    ShareLink("Share", item: viewModel.steps.joined(separator: "\n"))
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        .accessibilityLabel("Share steps")
                }
            }
            
            if viewModel.isLoading {
                ProgressView().padding(.top, 4.0)
            }
            
            if let message = viewModel.errorMessage {
                Text(message)
                    .foregroundStyle(.red)
                    .font(Design.Fonts.label)
                    .padding(.top, Design.Spacing.xs)
            }
            
            Divider().padding(.vertical, Design.Spacing.sm)
            
            //Steps List
            List {
                ForEach(Array(viewModel.steps.enumerated()), id: \.offset) { _, step in
                        Text(step)
                            .font(Design.Fonts.mono)
                            .monospacedDigit()
                    }
            }
            .listStyle(.plain)
            .animation(.snappy(duration: 0.2), value: viewModel.steps) // smooth insert/remove
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.vertical)
    }
    
    private func rightpanel(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: Design.Spacing.lg) {
                // Step Back
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    boardVM.stepBackward()
                } label: {
                    Image(systemName: "arrowtriangle.backward.fill")
                        .imageScale(.large)
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityLabel("Step Back")
                }
                .disabled(!boardVM.hasQueue || boardVM.isAtStart || boardVM.isPlaying)

                // Play / Pause
                Button(boardVM.isPlaying ? "Pause" : "Play") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    boardVM.isPlaying ? boardVM.pause() : boardVM.play()
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                .controlSize(.large)
                .frame(minWidth: 88)

                // Reset
                Button("Reset") {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    boardVM.reset(diskCount: viewModel.diskCount)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                .controlSize(.large)
                .frame(minWidth: 88)

                // Step Forward
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    boardVM.stepForward()
                } label: {
                    Image(systemName: "arrowtriangle.forward.fill")
                        .imageScale(.large)
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityLabel("Step Forward")
                }
                .disabled(!boardVM.hasQueue || boardVM.isAtEnd || boardVM.isPlaying)

                Text(boardVM.progressText)
                    .font(Design.Fonts.note)
                    .monospacedDigit()
                    .padding(.leading, 4)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Speed")
                        .font(Design.Fonts.note)

                    let minSpeed: Double = 0.1
                    let maxSpeed: Double = 2.0
                    Slider(
                        value: Binding(
                            get: { (minSpeed + maxSpeed) - boardVM.speed },
                            set: { newVal in
                                boardVM.speed = max(minSpeed, min(maxSpeed, (minSpeed + maxSpeed) - newVal))
                            }
                        ),
                        in: minSpeed...maxSpeed
                    )
                    .frame(width: 140) // short, fits screen
                    .accessibilityLabel("Playback Speed")
                }
            }
            .padding(.trailing, max(geo.safeAreaInsets.trailing, 22) + 8)

            // Playable zone
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: .init(lineWidth: 2, dash: [6,6]))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .padding(.leading, 14)
                    .padding(.trailing, max(geo.safeAreaInsets.trailing, 18))

                BoardView(viewModel: boardVM)
                    .padding(.leading, 18)
                    .padding(.trailing, max(geo.safeAreaInsets.trailing, 24) + 40)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 16) + 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight:.infinity, alignment: .topLeading)
        .padding(.vertical)
    }
}

#Preview {
    HomeView()
}
