//
//  QuoteManager.swift
//  MotiFy
//
//  Created by Daniel on 8/15/23.
//

import Foundation

/// An actor responsible for managing fetching and handling inspirational quotes.
actor QuoteManager {
    
    /// Private initializer to enforce singleton pattern.
    private init() {}
    
    /// The shared instance of the QuoteManager.
    static let shared: QuoteManager = QuoteManager()
    
    /// Fetch an inspirational quote asynchronously.
    /// - Returns: A `QuoteHolder` containing the fetched quote and the date it was updated.
    /// - Throws: An error if the quote fetching process encounters an issue.
    func fetchQuote() async throws -> QuoteHolder {
        // Headers required for the API request.
        let headers = [
            "X-RapidAPI-Key": "2366186accmsh184e71bf5cce5d0p15ee0djsn01dfff778bdc",
            "X-RapidAPI-Host": "quotes-inspirational-quotes-motivational-quotes.p.rapidapi.com"
        ]
        
        // Create the API request.
        var request = URLRequest(url: URL(string: "https://quotes-inspirational-quotes-motivational-quotes.p.rapidapi.com/quote?token=ipworld.info")!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        // Perform the API request and decode the JSON response.
        let result = try await URLSession.shared.data(for: request)
        let quote = try JSONDecoder().decode(Quote.self, from: result.0)
        
        // Create a QuoteHolder instance with the fetched quote and current date.
        let holder = QuoteHolder(dateUpdated: .now, quote: quote)
        
        return holder
    }
}
