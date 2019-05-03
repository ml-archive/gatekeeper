import Vapor

public struct Gatekeeper: Service {

    internal let config: GatekeeperConfig
    internal let cacheFactory: ((Container) throws -> KeyedCache)

    public init(
        config: GatekeeperConfig,
        cacheFactory: @escaping ((Container) throws -> KeyedCache) = { container in try container.make() }
    ) {
        self.config = config
        self.cacheFactory = cacheFactory
    }

    public func accessEndpoint(
        on request: Request
    ) throws -> Future<Gatekeeper.Entry> {

        guard let peerHostName = request.http.remotePeer.hostname else {
            throw Abort(
                .forbidden,
                reason: "Unable to verify peer"
            )
        }

        let peerCacheKey = cacheKey(for: peerHostName)
        let cache = try cacheFactory(request)

        return cache.get(peerCacheKey, as: Entry.self)
            .map(to: Entry.self) { entry in
                if let entry = entry {
                    return entry
                } else {
                    return Entry(
                        peerHostname: peerHostName,
                        createdAt: Date(),
                        requestsLeft: self.config.limit
                    )
                }
            }
            .map(to: Entry.self) { entry in

                let now = Date()
                var mutableEntry = entry
                if now.timeIntervalSince1970 - entry.createdAt.timeIntervalSince1970 >= self.config.refreshInterval {
                    mutableEntry.createdAt = now
                    mutableEntry.requestsLeft = self.config.limit
                }
                mutableEntry.requestsLeft -= 1
                return mutableEntry
            }.then { entry in
                return cache.set(peerCacheKey, to: entry).transform(to: entry)
            }.map(to: Entry.self) { entry in

                if entry.requestsLeft < 0 {
                    throw Abort(
                        .tooManyRequests,
                        reason: "Slow down. You sent too many requests."
                    )
                }
                return entry
            }
    }

    private func cacheKey(for hostname: String) -> String {
        return "gatekeeper_\(hostname)"
    }
}

extension Gatekeeper {
    public struct Entry: Codable {
        let peerHostname: String
        var createdAt: Date
        var requestsLeft: Int
    }
}
