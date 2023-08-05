//
//  ContentView.swift
//  MotiFy
//
//  Created by Daniel on 8/3/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView(selection: .constant(2)) {
            QuoteTabView()
                .tabItem { Image(systemName: "quote.opening") }
            
            TimerTabView()
                .tag(2)
                .tabItem { Image(systemName: "timer") }
            
            Text("Music")
                .tabItem { Image(systemName: "music.note") }
        }
    }
}

#Preview {
    ContentView()
}
