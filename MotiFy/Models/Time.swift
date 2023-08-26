//
//  Time.swift
//  MotiFy
//
//  Created by Daniel on 8/17/23.
//

import Foundation

struct Time: Codable, Equatable, Hashable {
    var hours: Int // Hours component of the time
    var minutes: Int // Minutes component of the time
    var seconds: Int // Seconds component of the time
    
    var timeInterval: TimeInterval { // Convert time components to TimeInterval
        TimeInterval(hours * 3600 + minutes * 60 + seconds)
    }
    
    var formatted: String { // Formatted time in HH:mm:ss format
        let formattedHours = String(format: "%02d", hours)
        let formattedMinutes = String(format: "%02d", minutes)
        let formattedSeconds = String(format: "%02d", seconds)
        return "\(formattedHours):\(formattedMinutes):\(formattedSeconds)"
    }

    // Initializer to create a Time instance with default values
    init(hours: Int = 0, minutes: Int = 0, seconds: Int = 0) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
    }
    
    // Initializer to create a Time instance from a TimeInterval
    init(from interval: TimeInterval) {
        let totalSeconds = Int(interval)
        self.hours = totalSeconds / 3600
        self.minutes = (totalSeconds % 3600) / 60
        self.seconds = totalSeconds % 60
    }
}
