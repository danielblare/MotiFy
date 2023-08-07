//
//  QuoteTabView.swift
//  MotiFy
//
//  Created by Daniel on 8/3/23.
//

import SwiftUI

@MainActor
final class QuoteTabViewModel: ObservableObject {
    
    @Published private(set) var quoteHolder: QuoteHolder?
    
    @Published var alert: AlertData?
      
    init() {
        if let data = UserDefaults.standard.data(forKey: "quote"),
           let quote = try? JSONDecoder().decode(QuoteHolder.self, from: data) {
            self.quoteHolder = quote
        }
        
        guard let quoteHolder, Calendar.current.isDateInToday(quoteHolder.dateUpdated) else {
            fetchQuote()
            return
        }
    }
    
    func fetchQuote() {
        print("Fetching")
        let headers = [
            "X-RapidAPI-Key": "2366186accmsh184e71bf5cce5d0p15ee0djsn01dfff778bdc",
            "X-RapidAPI-Host": "quotes-inspirational-quotes-motivational-quotes.p.rapidapi.com"
        ]
        
        var request = URLRequest(url: URL(string: "https://quotes-inspirational-quotes-motivational-quotes.p.rapidapi.com/quote?token=ipworld.info")!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        Task {
            do {
                let result = try await URLSession.shared.data(for: request)
                let quote = try JSONDecoder().decode(Quote.self, from: result.0)
                
                let holder = QuoteHolder(dateUpdated: .now, quote: quote)
                
                let data = try JSONEncoder().encode(holder)
                UserDefaults.standard.setValue(data, forKey: "quote")
                
                self.quoteHolder = holder
                
            } catch {
                alert = AlertData(title: "Error while fetching quote", message: error.localizedDescription)
            }
        }

    }
    
    
}

struct QuoteTabView: View {
    
    @StateObject private var viewModel: QuoteTabViewModel = .init()

    var body: some View {
        VStack {
            Text("Quote of the day")
                .font(.title2)
                .foregroundStyle(.accent)

            Spacer()
            
            Quote

            Spacer()
        }
            .padding()
            .background {
                FancyBackground()
                    .blur(radius: 3)
            }
    }
    
    private var Quote: some View {
        VStack(alignment: .leading) {
            if let quote = viewModel.quoteHolder?.quote {
                Image(systemName: "quote.opening")

                Text(quote.text)
                    .font(.title)
                    .fontDesign(.serif)
                    .padding(.vertical)
                
                Text("- \(quote.author)")
                    .fontDesign(.serif)
                    .italic()
                    .foregroundStyle(.secondary)
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                LoadingBouncyView(timeInterval: 0.3)
            }
        }
    }
}

#Preview {
    QuoteTabView()
}
