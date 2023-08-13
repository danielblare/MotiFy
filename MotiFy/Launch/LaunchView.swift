//
//  LaunchView.swift
//  MotiFy
//
//  Created by Daniel on 8/13/23.
//

import SwiftUI

struct LaunchView: View {
    
    @Binding private var showLaunchView: Bool
    @State private var logoScale: Double = 1
    @State private var blobsScale: Double = 1
    @State private var rotation: Angle = .zero
    
    init(_ showLaunchView: Binding<Bool>) {
        self._showLaunchView = showLaunchView
    }
    
    var body: some View {
        ZStack {
            Image("blobs")
                .resizable()
                .scaledToFit()
                .scaleEffect(blobsScale)
                .rotationEffect(rotation)
                .frame(width: 400, height: 400)
                .padding(.top, 20)
            
            Image("logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(logoScale)
                .frame(width: 150, height: 150)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(Color.background)
        .task {
            try? await Task.sleep(for: .seconds(0.3))
            
            withAnimation(.bouncy(duration: 0.4)) {
                logoScale = 1.1
            }
            try? await Task.sleep(for: .seconds(0.6))
            
            withAnimation(.bouncy(duration: 0.2, extraBounce: 0.4)) {
                logoScale = 1.5
            }
            
            withAnimation(.bouncy(duration: 0.6, extraBounce: 0.4)) {
                blobsScale = 3
                rotation = .degrees(90)
            }
            
            try? await Task.sleep(for: .seconds(1))
            
            withAnimation(.smooth(duration: 0.2)) {
                logoScale = 0
            }
            try? await Task.sleep(for: .seconds(0.2))
            
            withAnimation {
                showLaunchView = false
            }
        }
    }
}

#Preview {
    LaunchView(.constant(true))
}
