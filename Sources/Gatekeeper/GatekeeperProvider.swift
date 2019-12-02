import Vapor

public final class GatekeeperProvider {

    internal let config: GatekeeperConfig

    public init(config: GatekeeperConfig = GatekeeperConfig(maxRequests: 10, per: .second)) {
        self.config = config
    }
}

extension GatekeeperProvider: Provider {

    public func register(_ app: Application) {

        app.register(extension: MiddlewareConfiguration.self) { (configuration: inout MiddlewareConfiguration, app: Application) in

            let cache: GateKeeperCache = app.make()
            let gateKeeper = Gatekeeper(config: self.config, cache: cache)
            let middleware = GatekeeperMiddleware(gatekeeper: gateKeeper)
            configuration.use(middleware)
        }
    }

}
