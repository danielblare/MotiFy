//
//  Time.swift
//  MotiFy
//
//  Created by Daniel on 8/17/23.
//

import Foundation

struct Time: Codable, Equatable, Hashable {
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
