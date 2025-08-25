//
//  HomeView.swift
//  HanoiGame
//
//  Created by Alberto Orrantia on 22/08/25.
//

import SwiftUI

struct HomeView: View {
    
    @State private var viewModel = HanoiViewModel()
    
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
        RoundedRectangle(cornerRadius: 12.0)
            .stroke(style: .init(lineWidth: 2.0, dash: [6.0, 6.0]))
            .overlay {
                Text("Board View (next)")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.vertical)
    }
}


#Preview {
    HomeView()
}
