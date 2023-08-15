//
//  Provider.swift
//  MotiFy
//
//  Created by Daniel on 8/15/23.
//

import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> DataEntry {
        .placeholderInstance
    }

    func getSnapshot(in context: Context, completion: @escaping (DataEntry) -> ()) {
        Task {
            if let holder = try? await QuoteManager.shared.fetchQuote() {
                completion(DataEntry(date: .now, quote: holder.quote))
            } else {
                completion(.placeholderInstance)
            }
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DataEntry>) -> ()) {
        Task {
            let currentDate = Date()
            let calendar = Calendar.current
            let date = calendar.startOfDay(for: currentDate).addingTimeInterval(24 * 60 * 60)
            
            let holder = try? await QuoteManager.shared.fetchQuote()
            
            let quote = holder?.quote ?? .testInstance
            
            let timeline = Timeline(entries: [DataEntry(date: date, quote: quote)], policy: .after(date))
            completion(timeline)
        }
    }
}
