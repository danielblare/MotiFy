//
//  LoadingBouncyView.swift
//  MotiFy
//
//  Created by Daniel on 8/3/23.
//

import SwiftUI

struct LoadingBouncyView: View {
    // Current phase of the animation
    @State private var phase: Int = 1
    
    // Total number of phases in the animation
    private let totalPhases: Int = 4
    
    // Time interval for transitioning between phases
    private let timeInterval: TimeInterval
    
    // Initialize the view with a given time interval
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }

    var body: some View {
        HStack {
            // Create circles for each phase
            ForEach(1..<4) { num in
                Circle()
                    .fill(.secondary)
                    // Adjust opacity based on the current phase
                    .opacity(num == phase ? 1 : 0.5)
                    // Offset the circle vertically for bouncing effect
                    .offset(.init(width: 0, height: num == phase ? -5 : 0))
                    .frame(width: 10, height: 10)
            }
        }
        // Apply bouncy animation to circles when the phase changes
        .animation(.bouncy, value: phase)
        .onAppear {
            // Set up a timer to update the phase at the specified time interval
            Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { timer in
                // Increment the phase and reset when it reaches the total phases
                phase += 1
                if phase == totalPhases {
                    phase = 0
                }
            }
        }
    }
}

#Preview {
    LoadingBouncyView(timeInterval: 0.3)
}
