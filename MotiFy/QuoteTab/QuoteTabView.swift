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
           let holder = try? JSONDecoder().decode(QuoteHolder.self, from: data) {
            self.quoteHolder = holder
        }

        
        guard let quoteHolder, Calendar.current.isDateInToday(quoteHolder.dateUpdated) else {
            Task {
                do {
                    let holder = try await QuoteManager.shared.fetchQuote()
                    
                    let data = try JSONEncoder().encode(holder)
                    UserDefaults.standard.setValue(data, forKey: "quote")
                    
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
                    .blur(radius: 2)
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
                    .lineLimit(1)
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
