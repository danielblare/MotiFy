//
//  QuoteTabView.swift
//  MotiFy
//
//  Created by Daniel on 8/3/23.
//

import SwiftUI

@MainActor
final class QuoteTabViewModel: ObservableObject {
    
    /// Published property to hold the quote data
    @Published private(set) var quoteHolder: QuoteHolder?
    
    /// Published property to manage alerts
    @Published var alert: AlertData?
    
    /// Initialize the view model
    init() {
        // Try to retrieve saved quote data from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "quote"),
           let holder = try? JSONDecoder().decode(QuoteHolder.self, from: data) {
            self.quoteHolder = holder
        }

        // Check if the quote data needs to be updated
        guard let quoteHolder, Calendar.current.isDateInToday(quoteHolder.dateUpdated) else {
            // If not updated or not available, fetch new quote
            Task {
                do {
                    let holder = try await QuoteManager.shared.fetchQuote()
                    
                    // Encode and store the fetched quote data in UserDefaults
                    let data = try JSONEncoder().encode(holder)
                    UserDefaults.standard.setValue(data, forKey: "quote")
                    
                    // Update the quoteHolder property with the new data
                    self.quoteHolder = holder

                } catch {
                    print(error)
                }
            }
            return
        }
    }
}


struct QuoteTabView: View {
    
    // Create an instance of QuoteTabViewModel as a StateObject
    @StateObject private var viewModel: QuoteTabViewModel = .init()

    var body: some View {
        VStack {
            // Title for the quote section
            Text("Quote of the day")
            .font(.title2)
                .foregroundStyle(.accent)

            Spacer()
            
            // Display the quote content using the Quote view
            QuoteView

            Spacer()
        }
        // Apply padding and a background with blurred effect
        .padding()
        .background {
            FancyBackground()
                .blur(radius: 2)
        }
    }
    
    private var QuoteView: some View {
        VStack(alignment: .leading) {
            if let quote = viewModel.quoteHolder?.quote {
                Image(systemName: "quote.opening")

                // Display the quote text
                Text(quote.text)
                    .font(.title)
                    .fontDesign(.serif)
                    .padding(.vertical)
                
                // Display the quote author
                Text("- \(quote.author)")
                    .lineLimit(1)
                    .fontDesign(.serif)
                    .italic()
                    .foregroundStyle(.secondary)
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                // Display a loading animation if quote data is not available yet
                LoadingBouncyView(timeInterval: 0.3)
            }
        }
    }
}


#Preview {
    QuoteTabView()
}
