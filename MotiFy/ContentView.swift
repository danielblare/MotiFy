//
//  ContentView.swift
//  MotiFy
//
//  Created by Daniel on 8/3/23.
//

import SwiftUI

struct ContentView: View {
    private let dependencies: Dependencies
    
    init(with dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    var body: some View {
        TabView {
            QuoteTabView()
                .tabItem { Image(systemName: "quote.opening") }
            
            TimerTabView()
                .tabItem { Image(systemName: "timer") }
            
            MusicTabView(with: dependencies)
                .tabItem { Image(systemName: "music.note") }
        }
    }
}

#Preview {
    ContentView(with: .testInstance)
}
