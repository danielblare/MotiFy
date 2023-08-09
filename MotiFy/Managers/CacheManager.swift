//
//  CacheManager.swift
//  MotiFy
//
//  Created by Daniel on 8/9/23.
//

import Foundation
import SwiftUI

final class CacheManager {
    
    let artWorkCache: NSCache<NSString, UIImage> = {
        var cache = NSCache<NSString, UIImage>()
        cache.countLimit = 50
        cache.totalCostLimit = 1024 * 1024 * cache.countLimit
        return cache
    }()
    
    func addTo<T : AnyObject>(_ cache: NSCache<NSString, T>, forKey key: String, value: T) {
        cache.setObject(value, forKey: key as NSString)
    }
    
    func delete<T : AnyObject>(from cache: NSCache<NSString, T>, forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    func getFrom<T : AnyObject>(_ cache: NSCache<NSString, T>, forKey key: String) -> T? {
        cache.object(forKey: key as NSString)
    }
}
