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
            // ** WARNING **
            // it's possible for a user to make a request using the scheme `https`
            // but over plaintext. If this is a concern, serve application
            // behind a proxy server, such as nginx, and have the proxy enforce
            // an SSL conntection.
            guard request.uri.scheme == "https" else {
                throw error
            }
        }
        
        let response = try next.respond(to: request)
        return response
    }
}
