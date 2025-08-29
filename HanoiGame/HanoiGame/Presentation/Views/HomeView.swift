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
                
                rightpanel
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: max(420, geo.size.height - 40))
                    .padding(.trailing, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showError = (newValue != nil)
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
                Button("OK", role: .cancel) { }
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
                        await viewModel.fetchSolution()

                        if let response = viewModel.lastResponse {
                            if let moves = response.moves {
                                await MainActor.run {
                                    boardVM.load(diskCount: response.diskCount, moves: moves)
                                }
                            } else {
                                await MainActor.run {
                                    boardVM.setDiskCountWithoutMoves(response.diskCount)
                                }
                            }
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
                
                Button("Clear") {
                    print(Environment.baseURL)
                    viewModel.clear()
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
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.vertical)
    }
    
    private var rightpanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Step Back
            HStack(spacing: Design.Spacing.lg) {
                
                //Step Back
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
            
            //Player Controls
                Button(boardVM.isPlaying ? "Pause" : "Play") {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    boardVM.isPlaying ? boardVM.pause() : boardVM.play()
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                .controlSize(.large)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: 88)
                .disabled(!boardVM.hasQueue || boardVM.isAtEnd)
                .accessibilityLabel(boardVM.isPlaying ? "Pause Animation" : "Play Animation")
                
                Button("Reset") {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    boardVM.reset(diskCount: viewModel.diskCount)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                .controlSize(.large)
                .frame(minWidth: 88)
                .accessibilityLabel("Reset board")
                
                
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
                
                Spacer(minLength: Design.Spacing.lg)

                //Progress
                Text(boardVM.progressText)
                    .font(Design.Fonts.note)
                    .monospacedDigit()
                
                Text("Speed") .font(Design.Fonts.note)
                Slider(value: Binding(
                        get: { boardVM.speed },
                        set: { boardVM.speed = max(0.1, $0) }),
                            in: 0.1...2.0)
                        .frame(minWidth: 160)
                        .accessibilityLabel("Playback Speed")
            }
            .font(Design.Fonts.label)
            .padding(.top, Design.Spacing.xs)
            
            //Board View (extra trailing/bottom gutter to avoid clipping on iPhone landscape)
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style: .init(lineWidth: 2, dash: [6,6]))
                    .foregroundStyle(.secondary.opacity(0.7))
                    .padding(.leading, 8)
                    .padding(.trailing, 54)   // ↑ more room on the right
                
                BoardView(viewModel: boardVM)
                    .padding(.leading, 12)
                    .padding(.trailing, 64)   // ↑ prevents right-edge chop
                    .padding(.bottom, 22)     // ↑ off the home pill
            }
            .padding(.trailing, 18)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight:.infinity, alignment: .topLeading)
        .padding(.vertical)
    }
}

#Preview {
    HomeView()
}
