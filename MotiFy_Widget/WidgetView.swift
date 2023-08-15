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
        .background {
            FancyBackground(blobSize: 15, quantity: 16, randomOpacity: true, staticView: true)
                .opacity(0.5)
                .blur(radius: 0.5)
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
        .background {
            FancyBackground(blobSize: 20, quantity: 36, randomOpacity: true, staticView: true)
                .opacity(0.5)
                .blur(radius: 0.5)
        }
    }
}
