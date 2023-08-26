//
//  QueueElement.swift
//  MotiFy
//
//  Created by Daniel on 8/25/23.
//

import Foundation

struct QueueElement: Equatable, Identifiable {
    let id: String // Unique identifier for the queue element
    let track: Track // The track associated with this queue element
    let autoplay: Bool // Flag indicating whether autoplay is enabled
    
    // Initialize a QueueElement with the given track and autoplay flag
    init(track: Track, autoplay: Bool = false) {
        self.track = track // Set the track for the queue element
        self.id = track.id // Use the track's id as the unique identifier
        self.autoplay = autoplay // Set the autoplay flag
    }
}
