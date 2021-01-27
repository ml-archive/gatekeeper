import Vapor

/// Uses the hostname of the client to create a cache key.
public struct GatekeeperHostnameKeyMaker: GatekeeperKeyMaker {
    public func make(for req: Request) -> EventLoopFuture<String> {
        guard let hostname = req.hostname else {
            return req.eventLoop.future(error: Abort(.forbidden, reason: "Unable to verify peer"))
        }
        
        return req.eventLoop.future("gatekeeper_" + hostname)
    }
}
