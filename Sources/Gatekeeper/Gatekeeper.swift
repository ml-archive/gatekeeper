import Vapor

public struct Gatekeeper {
    private let cache: Cache
    private let config: GatekeeperConfig
    private let keyMaker: GatekeeperKeyMaker
    
    public init(cache: Cache, config: GatekeeperConfig, identifier: GatekeeperKeyMaker) {
        self.cache = cache
        self.config = config
        self.keyMaker = identifier
    }
    
    public func gatekeep(
        on req: Request,
        throwing error: Error = Abort(.tooManyRequests, reason: "Slow down. You sent too many requests.")
    ) -> EventLoopFuture<Void> {
        keyMaker
            .make(for: req)
            .flatMap { cacheKey in
                fetchOrCreateEntry(for: cacheKey, on: req)
                    .guard(
                        { $0.requestsLeft > 0 },
                        else: error
                    )
                    .map(updateEntry)
                    .flatMap { entry in
                        // The amount of time the entry has existed.
                        let entryLifetime = Int(Date().timeIntervalSince1970 - entry.createdAt.timeIntervalSince1970)
                        // Remaining time until the entry expires. The entry would be expired by cache if it was negative.
                        let timeRemaining = Int(config.refreshInterval) - entryLifetime
                        return cache.set(cacheKey, to: entry, expiresIn: .seconds(timeRemaining))
                    }
            }
    }
    
    private func updateEntry(_ entry: Entry) -> Entry {
        var newEntry = entry
        newEntry.touch()
        return newEntry
    }
    
    private func fetchOrCreateEntry(for key: String, on req: Request) -> EventLoopFuture<Entry> {
        guard let hostname = req.hostname else {
            return req.eventLoop.future(error: Abort(.forbidden, reason: "Unable to verify peer"))
        }
        
        return cache
            .get(key, as: Entry.self)
            .unwrap(orReplace: Entry(hostname: hostname, createdAt: Date(), requestsLeft: config.limit))
    }
}
