//
//  TimeSelector.swift
//  MotiFy
//
//  Created by Daniel on 8/17/23.
//

import SwiftUI

struct TimeSelector: View {
    
    // Binding to the selected time value
    @Binding private var time: Time
        
    // Initialize the view with a time binding
    init(time: Binding<Time>) {
        self._time = time
    }
        
    var body: some View {
        // Horizontal stack to arrange the pickers
        HStack(spacing: 0) {
            // Picker for hours selection
            Picker("", selection: $time.hours) {
                ForEach(0..<24) {
                    // Display each hour as text
                    Text($0 < 10 ? "0\($0)" : "\($0)")
                }
            }
            // Set the width of the picker
            .frame(width: 50)
            
            // Display a colon separator
            Text(":")
            
            // Picker for minutes selection
            Picker("Minutes", selection: $time.minutes) {
                ForEach(0..<60) {
                    // Display each minute as text
                    Text($0 < 10 ? "0\($0)" : "\($0)")
                }
            }
            // Set the width of the picker
            .frame(width: 50)
            
            // Display a colon separator
            Text(":")
            
            // Picker for seconds selection
            Picker("Seconds", selection: $time.seconds) {
                ForEach(0..<60) {
                    // Display each second as text
                    Text($0 < 10 ? "0\($0)" : "\($0)")
                }
            }
            // Set the width of the picker
            .frame(width: 50)
        }
        // Use a monospaced font for digit alignment
        .monospacedDigit()
        // Apply the wheel-style appearance to pickers
        .pickerStyle(.wheel)
    }
}


#Preview {
    TimeSelector(time: .constant(Time.init()))
}
