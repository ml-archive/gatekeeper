import Vapor
import RedisKit

public struct Gatekeeper {

    internal let config: GatekeeperConfig
    internal let cache: GateKeeperCache

    public init(config: GatekeeperConfig, cache: GateKeeperCache) {
        self.config = config
        self.cache = cache
    }

    internal func accessEndpoint(on request: Request) throws -> EventLoopFuture<Gatekeeper.Entry> {

        guard let ipAddress = request.remoteAddress?.ipAddress else {
            throw Abort(.forbidden, reason: "Unable to verify peer")
        }

        let peerCacheKey = self.cacheKey(for: ipAddress)

        return self.cache.get(peerCacheKey, as: Entry.self)
            .map({ entry -> Gatekeeper.Entry in
                if let entry = entry {
                    return entry
                } else {
                    return Entry(ipAddress: ipAddress, createdAt: Date(), requestsLeft: self.config.limit)
                }
            }
            .map({ entry -> Gatekeeper.Entry in

                let now = Date()
                var mutableEntry = entry
                if now.timeIntervalSince1970 - entry.createdAt.timeIntervalSince1970 >= self.config.refreshInterval {
                    mutableEntry.createdAt = now
                    mutableEntry.requestsLeft = self.config.limit
                }
                mutableEntry.requestsLeft -= 1
                return mutableEntry
            })
            .then( { entry in
                return self.cache.set(peerCacheKey, to: entry).transform(to: entry)
            })
            .map({ entry in

                if entry.requestsLeft < 0 {
                    throw Abort(.tooManyRequests, reason: "Slow down. You sent too many requests.")
                }
                return entry
            })
    }

    private func cacheKey(for hostname: String) -> String { return "gatekeeper_\(hostname)" }
}

extension Gatekeeper {
    public struct Entry: Codable {
        let ipAddress: String
        var createdAt: Date
        var requestsLeft: Int
    }
}
