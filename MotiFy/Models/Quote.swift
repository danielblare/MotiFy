//
//  Quote.swift
//  MotiFy
//
//  Created by Daniel on 8/4/23.
//

import Foundation

struct QuoteHolder: Codable {
    let dateUpdated: Date
    let quote: Quote
}

struct Quote: Identifiable, Codable {
    var id: UUID
    
    let text: String
    let author: String
        
    init(id: UUID = UUID(), text: String, author: String) {
        self.id = id
        self.text = text
        self.author = author
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.text = try container.decode(String.self, forKey: .text)
        self.author = try container.decode(String.self, forKey: .author)
    }
    
    static let testInstance = Quote(text: "Well begun is half done", author: "Aristotle")
}
