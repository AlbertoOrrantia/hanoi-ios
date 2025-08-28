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
    
    var body: some View {
        HStack {
            leftpanel
            rightpanel
        }
        .padding(.horizontal)
        .onChange(of: viewModel.errorMessage) { _, newValue in
            showError = (newValue != nil)
        }
        .alert("Network Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
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
                    Task { await viewModel.fetchSolution() }
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
            List(viewModel.steps, id: \.self) { step in
                Text(step)
                    .font(Design.Fonts.mono)
                    .monospacedDigit()
            }
            .listStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.vertical)
    }
    
    private var rightpanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            //Player Controls
            HStack(spacing: Design.Spacing.lg) {
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
                .accessibilityLabel(boardVM.isPlaying ? "Pause Animation" : "Play Animation")
                
                Button("Reset") {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    boardVM.reset(diskCount: viewModel.diskCount)
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
                .controlSize(.large)
                .frame(minWidth: 88)
                .accessibilityLabel("Reset baord")
                
                Spacer(minLength: Design.Spacing.lg)
                
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
            
            //Board View
            BoardView(viewModel: boardVM)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(style: .init(lineWidth: 2,dash: [6,6]))
                        .foregroundStyle(.secondary.opacity(0.7))
                )
        }
        .frame(maxWidth: .infinity, maxHeight:.infinity, alignment: .topLeading)
        .padding(.vertical)
    }
}


#Preview {
    HomeView()
}
