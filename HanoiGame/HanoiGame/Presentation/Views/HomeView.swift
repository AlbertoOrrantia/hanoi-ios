//
//  HomeView.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 22/08/25.
//

import SwiftUI

struct HomeView: View {
    
    @State private var viewModel = HanoiViewModel()
    @State private var boardVM = BoardViewModel()
    
    var body: some View {
        HStack {
            leftpanel
            rightpanel
        }
        .padding(.horizontal)
    }
    
    //MARK: - Panels
    
    private var leftpanel: some View {
        VStack(alignment: .leading, spacing: 12.0) {
            
            Text("Hanoi Tower")
                .font(.title.bold())
            
            //Disk Selector
            Stepper("Disks: \(viewModel.diskCount)",
                    value: $viewModel.diskCount,
                    in: 1...64)
            
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
                    .padding(.top, 4.0)
            }
            
            Divider().padding(.vertical, 6.0)
            
            //Steps List
            List(viewModel.steps, id: \.self) { step in
                Text(step)
                    .font(.callout)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.vertical)
    }
    
    private var rightpanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            
            //Player Controls
            HStack(spacing: 12) {
                Button(boardVM.isPlaying ? "Pause" : "Play") {
                    boardVM.isPlaying ? boardVM.pause() : boardVM.play()
                }
                .buttonStyle(.bordered)
                
                Button("Reset") {
                    boardVM.reset(diskCount: viewModel.diskCount)
                }
                
                Text("Speed")
                     Slider(value: Binding(
                        get: { boardVM.speed },
                        set: { boardVM.speed = max(0.1, $0) }),
                            in: 0.1...2.0)
                        .frame(width: 160)
            }
            .font(.callout)
            
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
