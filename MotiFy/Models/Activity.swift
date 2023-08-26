//
//  Activity.swift
//  MotiFy
//
//  Created by Daniel on 8/16/23.
//

import Foundation

struct Activity: Hashable, Identifiable, Codable {
    let id: String // Unique identifier for the activity
    var name: String // Name of the activity
    static let nameSymbolLimit = 20 // Symbol limit for the name
    var displayText: String // Text displayed during the activity
    static let displayTextSymbolLimit = 40 // Symbol limit for the display text
    var defaultTime: Time // Default time set for the activity

    // Initializer to create an Activity instance
    init(id: String = UUID().uuidString, name: String, displayText: String, defaultTime: Time = .init()) {
        self.id = id
        self.name = name
        self.displayText = displayText
        self.defaultTime = defaultTime
    }
    
    // Test instance for Activity
    static let testInstance = Activity(id: "test_id", name: "Work", displayText: "Work", defaultTime: .init(hours: 5, minutes: 30))
}
