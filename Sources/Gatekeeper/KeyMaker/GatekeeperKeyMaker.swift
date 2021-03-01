import Vapor

/// Reponsible for generating a cache key for a specific `Request`
public protocol GatekeeperKeyMaker {
    func make(for req: Request) -> EventLoopFuture<String>
}
