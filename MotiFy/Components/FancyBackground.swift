//
//  FancyBackground.swift
//  MotiFy
//
//  Created by Daniel on 8/6/23.
//

import SwiftUI

struct Meteorite: View {
    let screenSize: CGSize
    let circleSize: CGFloat
    let startPosition: CGPoint
    let startVelocity: CGPoint
    @State private var position: CGPoint
    @State private var velocity: CGPoint
    let color: Color

    init(screenSize: CGSize, circleSize: CGFloat, color: Color = .accentColor) {
        self.screenSize = screenSize
        self.circleSize = circleSize
        self.startPosition = CGPoint(x: CGFloat.random(in: 0...screenSize.width), y: CGFloat.random(in: 0...screenSize.height))
        self.startVelocity = CGPoint(x: CGFloat.random(in: 0.1...1), y: CGFloat.random(in: 0.5...1.5))
        self._position = State(initialValue: startPosition)
        self._velocity = State(initialValue: startVelocity)
        self.color = color
    }

    var body: some View {
        Circle()
            .frame(width: circleSize, height: circleSize)
            .foregroundStyle(color)
            .position(position)
            .onAppear() {
                self.position = self.startPosition
                self.velocity = self.startVelocity
            }
            .onReceive(Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()) { _ in
                self.updatePosition()
            }
    }

    private func updatePosition() {
        var newPosition = CGPoint(
            x: self.position.x + self.velocity.x,
            y: self.position.y + self.velocity.y
        )

        if newPosition.y - circleSize / 2 > screenSize.height {
            newPosition = CGPoint(x: -CGFloat.random(in: 0...screenSize.width/2), y: -CGFloat.random(in: 0...screenSize.height/2))
            velocity = CGPoint(x: CGFloat.random(in: 0.1...2), y: CGFloat.random(in: 0.5...1.5))
        }

        self.position = newPosition
    }
}

struct FancyBackground: View {
    let circleSize: CGFloat = 50
    let screenSize: CGSize = UIScreen.main.bounds.size

    var body: some View {
        ZStack {
            ForEach(0..<25) { _ in
                let randomColor = Color.palette.colorSet.randomElement() ?? .accentColor
                Meteorite(screenSize: screenSize, circleSize: circleSize, color: randomColor)
                    .opacity(Double.random(in: 0.1...0.8))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    FancyBackground()
}
