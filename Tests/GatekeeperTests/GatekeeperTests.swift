import XCTest
import XCTVapor
@testable import Gatekeeper

class GatekeeperTests: XCTestCase {
    func testGateKeeper() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.gatekeeper.config = .init(maxRequests: 10, per: .second)
        
        app.grouped(GatekeeperMiddleware()).get("test") { req -> HTTPStatus in
            return .ok
        }
        
        for i in 1...11 {
            try app.test(.GET, "test", headers: ["X-Forwarded-For": "::1"], afterResponse: { res in
                if i == 11 {
                    XCTAssertEqual(res.status, .tooManyRequests)
                } else {
                    XCTAssertEqual(res.status, .ok, "failed for request \(i) with status: \(res.status)")
                }
            })
        }
    }
    
    func testGateKeeperNoPeerReturnsForbidden() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.gatekeeper.config = .init(maxRequests: 10, per: .second)
        
        app.grouped(GatekeeperMiddleware()).get("test") { req -> HTTPStatus in
            return .ok
        }

        try app.test(.GET, "test", afterResponse: { res in
            XCTAssertEqual(res.status, .forbidden)
        })
    }
    
    func testGateKeeperForwardedSupported() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.gatekeeper.config = .init(maxRequests: 10, per: .second)
        
        app.grouped(GatekeeperMiddleware()).get("test") { req -> HTTPStatus in
            return .ok
        }

        try app.test(
            .GET,
            "test",
            beforeRequest: { req in
                req.headers.forwarded = [HTTPHeaders.Forwarded(for: "\"[::1]\"")]
            },
            afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
            }
        )
    }
    
    func testGateKeeperCountRefresh() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.gatekeeper.config = .init(maxRequests: 100, per: .second)
        app.grouped(GatekeeperMiddleware()).get("test") { req -> HTTPStatus in
            return .ok
        }
        
        for _ in 0..<50 {
            try app.test(.GET, "test", headers: ["X-Forwarded-For": "::1"], afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
            })
        }

        let entryBefore = try app.gatekeeper.caches.cache.get("gatekeeper_::1", as: Gatekeeper.Entry.self).wait()
        XCTAssertEqual(entryBefore!.requestsLeft, 50)

        Thread.sleep(forTimeInterval: 1)
        
        try app.test(.GET, "test", headers: ["X-Forwarded-For": "::1"], afterResponse: { res in
            XCTAssertEqual(res.status, .ok)
        })

        let entryAfter = try app.gatekeeper.caches.cache .get("gatekeeper_::1", as: Gatekeeper.Entry.self).wait()
        XCTAssertEqual(entryAfter!.requestsLeft, 99, "Requests left should've reset")
    }
    
    func testGatekeeperCacheExpiry() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        app.gatekeeper.config = .init(maxRequests: 5, per: .second)
        app.grouped(GatekeeperMiddleware()).get("test") { req -> HTTPStatus in
            return .ok
        }
        
        for _ in 1...5 {
            try app.test(.GET, "test", headers: ["X-Forwarded-For": "::1"], afterResponse: { res in
                XCTAssertEqual(res.status, .ok)
            })
        }
        
        let entryBefore = try app.gatekeeper.caches.cache.get("gatekeeper_::1", as: Gatekeeper.Entry.self).wait()
        XCTAssertEqual(entryBefore!.requestsLeft, 0)
        
        Thread.sleep(forTimeInterval: 1)
        
        try XCTAssertNil(app.gatekeeper.caches.cache.get("gatekeeper_::1", as: Gatekeeper.Entry.self).wait())
    }

    func testRefreshIntervalValues() {
        let expected: [(GatekeeperConfig.Interval, Double)] = [
            (.second, 1),
            (.minute, 60),
            (.hour, 3_600),
            (.day, 86_400)
        ]

        expected.forEach { interval, expected in
            let rate = GatekeeperConfig(maxRequests: 1, per: interval)
            XCTAssertEqual(rate.refreshInterval, expected)
        }
    }
    
    func testGatekeeperUsesKeyMaker() throws {
        struct DummyKeyMaker: GatekeeperKeyMaker {
            func make(for req: Request) -> EventLoopFuture<String> {
                req.eventLoop.future("dummy")
            }
        }
        
        let app = Application(.testing)
        defer { app.shutdown() }
        app.gatekeeper.config = .init(maxRequests: 10, per: .second)
        app.gatekeeper.keyMakers.use { _ in
            DummyKeyMaker()
        }
        
        app.grouped(GatekeeperMiddleware()).get("test") { req -> HTTPStatus in
            return .ok
        }
        
        try app.test(.GET, "test", headers: ["X-Forwarded-For": "::1"], afterResponse: { _ in })
        
        let entry = try app.gatekeeper.caches.cache.get("dummy", as: Gatekeeper.Entry.self).wait()
        XCTAssertNotNil(entry)
    }
    
    func testGatekeeperDefaultProviders() throws {
        let app = Application(.testing)
        defer { app.shutdown() }
        
        XCTAssertTrue(app.gatekeeper.keyMakers.keyMaker is GatekeeperHostnameKeyMaker)
    }
}
