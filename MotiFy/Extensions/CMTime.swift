//
//  CMTime.swift
//  MotiFy
//
//  Created by Daniel on 8/8/23.
//

import Foundation
import AVKit

extension CMTime: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let value = CMTimeGetSeconds(self)
        try container.encode(value)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(Double.self)
        self = CMTime(seconds: value, preferredTimescale: 600)
    }
}
