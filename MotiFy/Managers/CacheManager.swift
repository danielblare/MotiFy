//
//  CacheManager.swift
//  MotiFy
//
//  Created by Daniel on 8/9/23.
//

import Foundation
import SwiftUI

/// A utility class for managing caching operations.
final class CacheManager {
    
    /// The cache for storing UIImage objects related to artwork.
    let artWorkCache: NSCache<NSString, UIImage> = {
        var cache = NSCache<NSString, UIImage>()
        cache.countLimit = 50
        cache.totalCostLimit = 1024 * 1024 * cache.countLimit
        return cache
    }()
    
    /// Add a value to a specified cache with a given key.
    /// - Parameters:
    ///   - cache: The NSCache to add the value to.
    ///   - key: The key associated with the value in the cache.
    ///   - value: The value to be added to the cache.
    func addTo<T : AnyObject>(_ cache: NSCache<NSString, T>, forKey key: String, value: T) {
        cache.setObject(value, forKey: key as NSString)
    }
    
    /// Delete a value from a specified cache using a given key.
    /// - Parameters:
    ///   - cache: The NSCache to delete the value from.
    ///   - key: The key associated with the value in the cache.
    func delete<T : AnyObject>(from cache: NSCache<NSString, T>, forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    /// Retrieve a value from a specified cache using a given key.
    /// - Parameters:
    ///   - cache: The NSCache to retrieve the value from.
    ///   - key: The key associated with the value in the cache.
    /// - Returns: The value associated with the key in the cache, if available.
    func getFrom<T : AnyObject>(_ cache: NSCache<NSString, T>, forKey key: String) -> T? {
        cache.object(forKey: key as NSString)
    }
}
