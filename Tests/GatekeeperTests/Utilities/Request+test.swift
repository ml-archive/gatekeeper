import Gatekeeper
import HTTP
import Vapor

extension Request {
    static func test(
        gatekeeperConfig: GatekeeperConfig,
        url: URLRepresentable = "http://localhost:8080/test",
        peerName: String? = "::1",
        cacheFactory: ((Container) throws -> KeyedCache)? = nil
    ) throws -> Request {
        let config = Config()

        var services = Services()
        services.register(KeyedCache.self) { container in
            return MemoryKeyedCache()
        }

        if let cacheFactory = cacheFactory {
            try services.register(
                GatekeeperProvider(
                    config: gatekeeperConfig,
                    cacheFactory: cacheFactory
                )
            )
        } else {
            try services.register(
                GatekeeperProvider(
                    config: gatekeeperConfig
                )
            )
        }

        services.register(GatekeeperMiddleware.self)

        let sharedThreadPool = BlockingIOThreadPool(numberOfThreads: 2)
        sharedThreadPool.start()
        services.register(sharedThreadPool)
        
        let app = try Application(config: config, environment: .testing, services: services)
        let request = Request(
            http: HTTPRequest(
                method: .GET,
                url: url
            ),
            using: app
        )

        var http = request.http
        if let peerName = peerName {
            http.headers.add(name: .init("X-Forwarded-For"), value: peerName)
        }
        request.http = http

        return request
    }
}
