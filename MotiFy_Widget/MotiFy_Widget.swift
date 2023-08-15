//
//  MotiFy_Widget.swift
//  MotiFy_Widget
//
//  Created by Daniel on 8/15/23.
//

import WidgetKit
import SwiftUI

struct MotiFy_Widget: Widget {
    let kind: String = "MotiFy_Widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) {
            WidgetView(entry: $0)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("MotiFy Widget")
        .description("Keep motivational quote close to you")
    }
}
