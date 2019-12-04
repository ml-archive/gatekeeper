//
//  MemoryCache.swift
//  GatekeeperTests
//
//  Created by Tommy Hinrichsen on 04/12/2019.
//

import Foundation
import Gatekeeper
import Vapor

final class GateKeeperCacheMemoryCache: GateKeeperCache {

    var storage: [String: Any]
    var lock: Lock

    init() {
        self.storage = [:]
        self.lock = .init()

    }

    public func get<D>(_ key: String, as type: D.Type) -> EventLoopFuture<D?> where D : Decodable {

        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
        if let value: D = self.get(key) {
            let future = eventLoop.makeSucceededFuture(value)
            return future.map{ $0 }
        } else {
            let future: EventLoopFuture<D?> = eventLoop.makeFailedFuture(GateKeeperTestError.notFound)
            return future
        }
    }

    public func set<E>(_ key: String, to entity: E) -> EventLoopFuture<Void> where E : Encodable {
        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1).next()
        let future = eventLoop.makeSucceededFuture(Void())
        return future
    }

    func get<E>(_ key: String) -> E? where E : Decodable {
        self.lock.lock()
        defer { self.lock.unlock() }
        return self.storage[key] as? E
    }

    func set<E>(_ key: String, to value: E?) where E : Encodable {
        self.lock.lock()
        defer { self.lock.unlock() }
        self.storage[key] = value
    }
}

