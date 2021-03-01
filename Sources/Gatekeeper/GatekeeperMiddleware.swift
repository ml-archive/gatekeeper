import Vapor

/// Middleware used to rate-limit a single route or a group of routes.
public struct GatekeeperMiddleware: Middleware {
    private let config: GatekeeperConfig?
    
    /// Initialize with a custom `GatekeeperConfig` instead of using the default `app.gatekeeper.config`
    public init(config: GatekeeperConfig? = nil) {
        self.config = config
    }
    
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        request
            .gatekeeper(config: config)
            .gatekeep(on: request)
            .flatMap { next.respond(to: request) }
    }
}
