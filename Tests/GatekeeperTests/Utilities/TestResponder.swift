import Vapor

public struct TestResponder: Responder {

    public func respond(to req: Request) -> EventLoopFuture<Response> {
        let response = Response()
        return req.eventLoop.future(response)
    }
}
