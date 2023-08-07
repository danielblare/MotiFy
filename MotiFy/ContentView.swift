//
//  ContentView.swift
//  MotiFy
//
//  Created by Daniel on 8/3/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            QuoteTabView()
                .tabItem { Image(systemName: "quote.opening") }
            
            TimerTabView()
                .tabItem { Image(systemName: "timer") }
            
            MusicTabView()
                .tabItem { Image(systemName: "music.note") }
        }
    }
}

#Preview {
    ContentView()
}
