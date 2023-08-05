//
//  Quote.swift
//  MotiFy
//
//  Created by Daniel on 8/4/23.
//

import Foundation

struct Quote: Identifiable, Codable {
    var id: UUID
    
    let text: String
    let author: String
    
    let dataUpdated: Date
    
    init(id: UUID = UUID(), text: String, author: String) {
        self.id = id
        self.text = text
        self.author = author
        self.dataUpdated = .now
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.dataUpdated = .now
        self.text = try container.decode(String.self, forKey: .text)
        self.author = try container.decode(String.self, forKey: .author)
    }
    
    static let testInstance = Quote(text: "Well begun is half done", author: "Aristotle")
}
