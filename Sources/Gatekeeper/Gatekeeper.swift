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
    
    public func gatekeep(on req: Request) -> EventLoopFuture<Void> {
        keyMaker
            .make(for: req)
            .flatMap { cacheKey in
                fetchOrCreateEntry(for: cacheKey, on: req)
                    .map(updateEntry)
                    .flatMap { entry in
                        cache
                            .set(cacheKey, to: entry)
                            .transform(to: entry)
                    }
            }
            .guard(
                { $0.requestsLeft > 0 },
                else: Abort(.tooManyRequests, reason: "Slow down. You sent too many requests."))
            .transform(to: ())
    }
    
    private func updateEntry(_ entry: Entry) -> Entry {
        var newEntry = entry
        if newEntry.hasExpired(within: config.refreshInterval) {
            newEntry.reset(remainingRequests: config.limit)
        }
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
