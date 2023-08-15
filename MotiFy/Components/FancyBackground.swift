//
//  FancyBackground.swift
//  MotiFy
//
//  Created by Daniel on 8/6/23.
//

import SwiftUI

struct Blob: View {
    private let screenSize: CGSize
    private let blobSize: CGFloat
    private let startPosition: CGPoint
    private let startVelocity: CGPoint
    private let rotation: Angle
    @State private var position: CGPoint
    @State private var velocity: CGPoint
    private let BlobImage: Image
    private let staticView: Bool


    init(screenSize: CGSize, blobSize: CGFloat, staticView: Bool) {
        self.screenSize = screenSize
        self.blobSize = blobSize
        self.startPosition = CGPoint(x: CGFloat.random(in: 0...screenSize.width), y: CGFloat.random(in: 0...screenSize.height))
        self.startVelocity = CGPoint(x: CGFloat.random(in: 0.1...1), y: CGFloat.random(in: 0.5...1.5))
        self._position = State(initialValue: startPosition)
        self._velocity = State(initialValue: startVelocity)
        self.BlobImage = .blobs.blobSet.randomElement() ?? .blobs.blob1
        self.rotation = .degrees(.random(in: 0...360))
        self.staticView = staticView
    }

    var body: some View {
       BlobImage
            .resizable()
            .scaledToFit()
            .frame(width: blobSize, height: blobSize)
            .rotationEffect(rotation)
            .position(position)
            .onAppear() {
                self.position = self.startPosition
                self.velocity = self.startVelocity
            }
            .onReceive(Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()) { _ in
                if !staticView {
                    self.updatePosition()
                }
            }
    }

    private func updatePosition() {
        var newPosition = CGPoint(
            x: self.position.x + self.velocity.x,
            y: self.position.y + self.velocity.y
        )

        if newPosition.y - blobSize / 2 > screenSize.height {
            newPosition = CGPoint(x: -CGFloat.random(in: 0...screenSize.width/2), y: -CGFloat.random(in: 0...screenSize.height/2))
            velocity = CGPoint(x: CGFloat.random(in: 0.1...2), y: CGFloat.random(in: 0.5...1.5))
        }

        self.position = newPosition
    }
}

struct FancyBackground: View {
    private let blobSize: CGFloat
    private let quantity: Int
    private let randomOpacity: Bool
    private let staticView: Bool
    
    init(blobSize: CGFloat = 60, quantity: Int = 25, randomOpacity: Bool = true, staticView: Bool = false) {
        self.blobSize = blobSize
        self.quantity = quantity
        self.randomOpacity = randomOpacity
        self.staticView = staticView
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<quantity) { _ in
                    Blob(screenSize: proxy.size, blobSize: blobSize, staticView: staticView)
                        .opacity(randomOpacity ? Double.random(in: 0.1...0.8) : 1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }
    
    private func getRandomColor() -> Color {
        Color.palette.colorSet.randomElement() ?? .accentColor
    }
}

#Preview {
    FancyBackground(blobSize: 60, quantity: 50, randomOpacity: true, staticView: true)
}
