import Vapor

public struct TestResponder: Responder {
    public func respond(to req: Request) throws -> EventLoopFuture<Response> {
        return req.future(req.response())
    }
}
