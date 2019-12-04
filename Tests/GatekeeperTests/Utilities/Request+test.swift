import Gatekeeper
import Vapor

extension Request {
    static func test(
        url: URI = URI(string: "http://localhost:8080/test"),
        gatekeeperConfig: GatekeeperConfig = GatekeeperConfig(maxRequests: 10, per: .second),
        peerName: String? = "::1"
    ) throws -> Request {

        let app =  Application(environment: .development)
        app.register(GateKeeperCache.self) { (app: Application) in
            return GateKeeperCacheMemoryCache()
        }
        app.provider(GatekeeperProvider(config: gatekeeperConfig))

        let eventLoop = MultiThreadedEventLoopGroup(numberOfThreads: 1) //???
        let request = Request(
            application: app,
            url: url,
            on: eventLoop.next()
        )

        if let peerName = peerName {
            request.headers.add(name: "X-Forwarded-For", value: peerName)
        }

        return request
    }
}
