import Vapor

public extension Request {
    func gatekeeper(
        config: GatekeeperConfig? = nil,
        cache: Cache? = nil,
        keyMaker: GatekeeperKeyMaker? = nil
    ) -> Gatekeeper {
        .init(
            cache: cache ?? application.gatekeeper.caches.cache.for(self),
            config: config ?? application.gatekeeper.config,
            identifier: keyMaker ?? application.gatekeeper.keyMakers.keyMaker
        )
    }
}
