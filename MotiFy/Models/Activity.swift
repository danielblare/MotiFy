//
//  Activity.swift
//  MotiFy
//
//  Created by Daniel on 8/16/23.
//

import Foundation

struct Activity: Hashable, Identifiable, Codable {
    let id: String
    var name: String
    static let nameSymbolLimit = 20
    var displayText: String
    static let displayTextSymbolLimit = 40
    var defaultTime: Time

    init(id: String = UUID().uuidString, name: String, displayText: String, defaultTime: Time = .init()) {
        self.id = id
        self.name = name
        self.displayText = displayText
        self.defaultTime = defaultTime
    }
    
    static let testInstance = Activity(id: "test_id", name: "Work", displayText: "Work", defaultTime: .init(hours: 5, minutes: 30))
}
