//
//  CacheService.swift
//  Reels
//
//  Created by Eugene on 11/5/2023.
//

import Foundation

protocol CacheService<Key, Value> {
    associatedtype Key: Hashable
    associatedtype Value
    
    subscript(key: Key) -> Value? { get set }
    func setValue(_ value: Value?, for key: Key)
    func value(for key: Key) -> Value?
    func removeValue(for key: Key)
    func removeAll()
}
