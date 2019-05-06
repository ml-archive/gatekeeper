import Vapor

public final class GatekeeperProvider {

    internal let config: GatekeeperConfig
    internal let cacheFactory: ((Container) throws -> KeyedCache)

    public init(
        config: GatekeeperConfig,
        cacheFactory: @escaping ((Container) throws -> KeyedCache) = { container in try container.make() }
    ) {
        self.config = config
        self.cacheFactory = cacheFactory
    }
}

extension GatekeeperProvider: Provider {
    public func register(_ services: inout Services) throws {
        services.register(config)
        services.register(
            Gatekeeper(
                config: config,
                cacheFactory: cacheFactory
            ),
            as: Gatekeeper.self
        )
        services.register(GatekeeperMiddleware.self)
    }

    public func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        return .done(on: container)
    }
}
