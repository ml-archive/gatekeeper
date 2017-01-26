import HTTP
import Vapor

public struct RateLimiter: Middleware {
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        let response = try next.respond(to: request)
        return response
    }
}

public struct SSLEnforcer: Middleware {
    private var shouldEnforce: Bool
    private let error: AbortError
    
    public init(error: AbortError, drop: Droplet, environments: [Environment] = [.production]) {
        shouldEnforce = environments.contains(drop.environment)
        self.error = error
    }
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        if shouldEnforce {
            guard request.uri.scheme == "https" else {
                throw error
            }
        }
        let response = try next.respond(to: request)
        return response
    }
}
