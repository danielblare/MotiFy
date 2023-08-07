//
//  TimerTabView.swift
//  MotiFy
//
//  Created by Daniel on 8/5/23.
//

import SwiftUI

struct Time {
    var hours: Int
    var minutes: Int
    var seconds: Int
    
    var timeInterval: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }
    
    var formatted: String {
        let formattedHours = String(format: "%02d", hours)
        let formattedMinutes = String(format: "%02d", minutes)
        let formattedSeconds = String(format: "%02d", seconds)
        return "\(formattedHours):\(formattedMinutes):\(formattedSeconds)"
    }

    init(hours: Int = 0, minutes: Int = 0, seconds: Int = 0) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
    }
    
}

struct TimerTabView: View {
    @State private var timer: Timer? = nil
    @State private var isTimerRunning = false
    @State private var showTimer = false

    @State private var selectedTime: Time = .init()
    @State private var remainingTime: Time = .init()
    

    var body: some View {
        VStack {
            Text("Timer")
                .font(.title2)
                .foregroundStyle(.accent)

            Group {
                if showTimer {
                    Text(remainingTime.formatted)
                        .font(.system(size: 70))
                } else {
                    HStack(spacing: 0) {
                        Picker("Hours", selection: $selectedTime.hours) {
                            ForEach(0..<24) {
                                Text("\($0)")
                            }
                        }
                        .overlay(alignment: .trailing) {
                            Text("h")
                                .padding(.trailing)
                        }
                        
                        Picker("Minutes", selection: $selectedTime.minutes) {
                            ForEach(0..<60) {
                                Text("\($0)")
                            }
                        }
                        .overlay(alignment: .trailing) {
                            Text("m")
                                .padding(.trailing)
                        }

                        Picker("Seconds", selection: $selectedTime.seconds) {
                            ForEach(0..<60) {
                                Text("\($0)")
                            }
                        }
                        .overlay(alignment: .trailing) {
                            Text("s")
                                .padding(.trailing)
                        }

                    }
                    .pickerStyle(.inline)
                }
            }
            .frame(height: 300)

            HStack {
                
                Button("Cancel", role: .destructive, action: cancelTimer)
                    .disabled(isTimerRunning)
                
                Spacer(minLength: 0)
                
                Button(isTimerRunning ? "Pause" : "Start", action: isTimerRunning ? pauseTimer : startTimer) .foregroundStyle(isTimerRunning ? .yellow : .green)
            }
            .buttonStyle(.bordered)
            .padding()
            .animation(nil, value: showTimer)
            .animation(nil, value: isTimerRunning)

            Spacer()
        }
        .padding()
        .animation(.bouncy, value: showTimer)
        .background {
            if isTimerRunning {
                FancyBackground()
                    .blur(radius: 3)
            }
        }
        .animation(.bouncy, value: isTimerRunning)
    }
    
    private func startTimer() {
        guard timer == nil, selectedTime.timeInterval > 0 else {
            return
        }
        if !showTimer {
            remainingTime = selectedTime
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime.timeInterval > 0 {
                if remainingTime.seconds > 0 {
                    remainingTime.seconds -= 1
                    return
                }
                if remainingTime.minutes > 0 {
                    remainingTime.minutes -= 1
                        remainingTime.seconds = 59
                    return
                }
                if remainingTime.hours > 0 {
                    remainingTime.hours -= 1
                        remainingTime.minutes = 59
                        remainingTime.seconds = 59
                    return
                }
            } else {
                cancelTimer()
            }
        }
        isTimerRunning = true
        showTimer = true
    }
    
    func cancelTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
        showTimer = false
    }
    
    func pauseTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }
}

#Preview {
    TimerTabView()
        .background {
            FancyBackground()
                .blur(radius: 3)
        }
}
