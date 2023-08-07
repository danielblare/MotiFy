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

    init(playing: Bool, spacing: CGFloat? = nil, cornerRadius: CGFloat = 5) {
        self.playing = playing
        self.spacing = spacing
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: spacing) {
            ForEach(1..<5) { num in
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .frame(height: proxy.size.height * (animate && playing ? CGFloat.random(in: 0.2...1) : 0.2))
                }
            }
        }
        .onReceive(Timer.publish(every: 0.3, on: .main, in: .common).autoconnect()) { _ in
            withAnimation(.linear) {
                animate.toggle()
            }
        }
        .rotationEffect(.degrees(180))
//        .onAppear {
//            withAnimation(.linear(duration: 0.3).repeatForever()) {
////                height = 0.2
//                animate = true
//            }
//        }
    }
}

#Preview {
    MusicPlayingAnimation(playing: true)
        .frame(width: 100, height: 100)
}
