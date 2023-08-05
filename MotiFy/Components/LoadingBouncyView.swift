//
//  LoadingBouncyView.swift
//  MotiFy
//
//  Created by Daniel on 8/3/23.
//

import SwiftUI

struct LoadingBouncyView: View {
    
    @State private var phase: Int = 1
    private let totalPhases: Int = 4
    private let timeInterval: TimeInterval
    
    init(timeInterval: TimeInterval) {
        self.timeInterval = timeInterval
    }

    var body: some View {
        HStack {
            ForEach(1..<4) { num in
                Circle()
                    .fill(.secondary)
                    .opacity(num == phase ? 1 : 0.5)
                    .offset(.init(width: 0, height: num == phase ? -5 : 0))
                    .frame(width: 10, height: 10)
            }
        }
        .animation(.bouncy, value: phase)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: true) { timer in
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
