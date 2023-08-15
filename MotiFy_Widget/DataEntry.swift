//
//  DataEntry.swift
//  MotiFy_WidgetExtension
//
//  Created by Daniel on 8/15/23.
//

import WidgetKit

struct DataEntry: TimelineEntry {
    let date: Date
    let quote: Quote
    
    static let placeholderInstance: DataEntry = DataEntry(date: .now, quote: .testInstance)
}
