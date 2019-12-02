import Vapor

public struct GatekeeperMiddleware {
    let gatekeeper: Gatekeeper
}

extension GatekeeperMiddleware: Middleware {
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        do {
            let response = try gatekeeper.accessEndpoint(on: request).flatMap { _ in return next.respond(to: request) }
            return response
        } catch  {
            return request.eventLoop.makeFailedFuture(error)
        }
    }
}
