//
//  MemoryCache.swift
//  Reels
//
//  Created by Eugene on 11/5/2023.
//

import Foundation

class MemoryCache<K: Hashable, V>: CacheService {
    typealias Key = K
    typealias Value = V
    
    #warning("TODO: implement capacity logic, introduce both object count and memory size rules")
    let capacity: Int
    private var dict = [K: V]()
    
    init(capacity: Int = 100) {
        self.capacity = capacity
    }
    
    subscript(key: Key) -> Value? {
        get { return value(for: key) }
        set { setValue(newValue, for: key) }
    }
    
    func setValue(_ value: Value?, for key: Key) {
        dict[key] = value
    }
    
    func value(for key: Key) -> Value? {
        return dict[key]
    }
    
    func removeValue(for key: Key) {
        dict[key] = nil
    }
    
    func removeAll() {
        dict.removeAll()
    }
}
