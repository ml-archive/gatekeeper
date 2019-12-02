//
//  File.swift
//  
//
//  Created by Tommy Hinrichsen on 02/12/2019.
//

import Foundation
import Vapor

public protocol GateKeeperCache {

    /// Gets key as a decodable type.
    func get<D>(_ key: String, as type: D.Type) -> EventLoopFuture<D?> where D: Decodable

    /// Sets key to an encodable item.
    func set<E>(_ key: String, to entity: E) -> EventLoopFuture<Void> where E: Encodable
}


