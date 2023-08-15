//
//  WidgetView.swift
//  MotiFy_WidgetExtension
//
//  Created by Daniel on 8/15/23.
//

import WidgetKit
import SwiftUI

struct WidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            Text("Not implemented")
        }
    }
}

struct SmallWidgetView: View {
    let entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "quote.opening")

            Spacer()
            
            Text(entry.quote.text)
                .fontDesign(.serif)
            
            Spacer()

            Text("- \(entry.quote.author)")
                .lineLimit(1)
                .font(.footnote)
                .fontDesign(.serif)
                .italic()
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

struct MediumWidgetView: View {
    let entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "quote.opening")
            
            Spacer()
            
            Text(entry.quote.text)
                .fontDesign(.serif)
                .font(.title3)
            
            Spacer()

            Text("- \(entry.quote.author)")
                .lineLimit(1)
                .font(.callout)
                .fontDesign(.serif)
                .italic()
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }

    }
}

#Preview(as: .systemMedium) {
    MotiFy_Widget()
} timeline: {
    DataEntry.placeholderInstance
}
