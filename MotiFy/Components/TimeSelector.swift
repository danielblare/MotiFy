//
//  TimeSelector.swift
//  MotiFy
//
//  Created by Daniel on 8/17/23.
//

import SwiftUI

struct TimeSelector: View {
    
    @Binding private var time: Time
        
    init(time: Binding<Time>) {
        self._time = time
    }
        
    var body: some View {
        HStack(spacing: 0) {
            Picker("", selection: $time.hours) {
                ForEach(0..<24) {
                    Text($0 < 10 ? "0\($0)" : "\($0)")
                }
            }
            .frame(width: 50)
            
            Text(":")

            Picker("Minutes", selection: $time.minutes) {
                ForEach(0..<60) {
                    Text($0 < 10 ? "0\($0)" : "\($0)")
                }
            }
            .frame(width: 50)

            Text(":")

            Picker("Seconds", selection: $time.seconds) {
                ForEach(0..<60) {
                    Text($0 < 10 ? "0\($0)" : "\($0)")
                }
            }
            .frame(width: 50)
        }
        .monospacedDigit()
        .pickerStyle(.wheel)
    }
}

#Preview {
    TimeSelector(time: .constant(Time.init()))
}
