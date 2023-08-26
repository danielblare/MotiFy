//
//  MusicPlayingAnimation.swift
//  MotiFy
//
//  Created by Daniel on 8/7/23.
//

import SwiftUI

struct MusicPlayingAnimation: View {
    @State private var height: Double = 1
    @State private var animate: Bool = false
    
    private let playing: Bool
    private let spacing: CGFloat?
    private let cornerRadius: CGFloat

    // Initialize the MusicPlayingAnimation view with properties
    init(playing: Bool, spacing: CGFloat? = nil, cornerRadius: CGFloat = 5) {
        self.playing = playing
        self.spacing = spacing
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            // Create a series of RoundedRectangle views with variable heights
            ForEach(1..<5) { num in
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .frame(height: proxy.size.height * (animate && playing ? CGFloat.random(in: 0.2...1) : 0.2))
                }
            }
        }
        // Animate the view's height changes with a timer
        .onReceive(Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()) { _ in
            withAnimation(.linear) {
                animate.toggle()
            }
        }
        // Rotate the entire view by 180 degrees
        .rotationEffect(.degrees(180))
    }
}

#Preview {
    MusicPlayingAnimation(playing: true)
        .frame(width: 100, height: 100)
}
