import Vapor

/// Middleware used to rate-limit a single route or a group of routes.
public struct GatekeeperMiddleware: Middleware {
    private let config: GatekeeperConfig?
    private let keyMaker: GatekeeperKeyMaker?
    private let error: Error?
    
    /// Initialize a new middleware for rate-limiting routes, by optionally overriding default configurations.
    ///
    /// - Parameters:
    ///     - config: Override `GatekeeperConfig` instead of using the default `app.gatekeeper.config`
    ///     - keyMaker: Override `GatekeeperKeyMaker` instead of using the default `app.gatekeeper.keyMaker`
    ///     - config: Override the `Error` thrown when the user is rate-limited instead of using the default error.
    public init(config: GatekeeperConfig? = nil, keyMaker: GatekeeperKeyMaker? = nil, error: Error? = nil) {
        self.config = config
        self.keyMaker = keyMaker
        self.error = error
    }
    
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        let gatekeeper = request.gatekeeper(config: config, keyMaker: keyMaker)
            
        let gatekeep: EventLoopFuture<Void>
        if let error = error {
            gatekeep = gatekeeper.gatekeep(on: request, throwing: error)
        } else {
            gatekeep = gatekeeper.gatekeep(on: request)
        }
        
        return gatekeep.flatMap { next.respond(to: request) }
    }
}
