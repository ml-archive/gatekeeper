import Vapor

public struct GatekeeperMiddleware {
    let gatekeeper: Gatekeeper
}

extension GatekeeperMiddleware: Middleware {
    public func respond(
        to request: Request,
        chainingTo next: Responder
    ) throws -> EventLoopFuture<Response> {

        return try gatekeeper.accessEndpoint(on: request).do { entry in
            print("Gatekeeper Entry: \(entry)")
        }.flatMap { _ in
            return try next.respond(to: request)
        }
    }
}

extension GatekeeperMiddleware: ServiceType {
    public static func makeService(for container: Container) throws -> GatekeeperMiddleware {
        return try .init(gatekeeper: container.make())
    }
}
