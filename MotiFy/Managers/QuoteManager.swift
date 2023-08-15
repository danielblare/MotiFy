//
//  QuoteManager.swift
//  MotiFy
//
//  Created by Daniel on 8/15/23.
//

import Foundation

final actor QuoteManager {
    
    private init() {}
    
    static let shared: QuoteManager = QuoteManager()
    
    func fetchQuote() async throws -> QuoteHolder {
        let headers = [
            "X-RapidAPI-Key": "2366186accmsh184e71bf5cce5d0p15ee0djsn01dfff778bdc",
            "X-RapidAPI-Host": "quotes-inspirational-quotes-motivational-quotes.p.rapidapi.com"
        ]
        
        var request = URLRequest(url: URL(string: "https://quotes-inspirational-quotes-motivational-quotes.p.rapidapi.com/quote?token=ipworld.info")!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let result = try await URLSession.shared.data(for: request)
        let quote = try JSONDecoder().decode(Quote.self, from: result.0)
        
        let holder = QuoteHolder(dateUpdated: .now, quote: quote)
        
        return holder
    }
}
