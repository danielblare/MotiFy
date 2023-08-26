//
//  Quote.swift
//  MotiFy
//
//  Created by Daniel on 8/4/23.
//

import Foundation

struct QuoteHolder: Codable {
    let dateUpdated: Date // Date when the quote was last updated
    let quote: Quote // The quote itself
}

struct Quote: Identifiable, Codable {
    var id: UUID // Unique identifier for the quote
    
    let text: String // The text content of the quote
    let author: String // The author of the quote
    
    init(id: UUID = UUID(), text: String, author: String) {
        self.id = id
        self.text = text
        self.author = author
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID() // Decode UUID or generate a new one if missing
        self.text = try container.decode(String.self, forKey: .text) // Decode the text content of the quote
        self.author = try container.decode(String.self, forKey: .author) // Decode the author of the quote
    }
    
    static let testInstance = Quote(text: "Well begun is half done", author: "Aristotle") // A test instance of Quote
}
