import XCTest

import URI
import HTTP
import Vapor

@testable import Gatekeeper

class GatekeeperTests: XCTestCase {
    static var allTests = [
        ("testRateLimiter", testRateLimiter),
    ]
    
    func testRateLimiter() {
        let middleware = RateLimiter(rate: Rate(10, per: .second))
        let request = getHTTPSRequest()
        
        for i in 1...11 {
            do {
                _ = try middleware.respond(to: request, chainingTo: MockResponder())
                XCTAssertTrue(i <= 10, "ran \(i) times.")
            } catch Abort.custom(status: let status, message: _) {
                XCTAssertEqual(status, .tooManyRequests)
                XCTAssertEqual(i, 11, "Should've failed after the 11th attempt.")
                break
            } catch {
                XCTFail("Caught wrong error: \(error)")
            }
        }
    }
    
    func testRateLimiterNoPeer() {
        let middleware = RateLimiter(rate: Rate(100, per: .second))
        let request = getHTTPRequest()
        
        do {
            _ = try middleware.respond(to: request, chainingTo: MockResponder())
        } catch Abort.custom(status: let status, message: _){
            XCTAssertEqual(status, .forbidden)
        } catch {
            XCTFail("Rate limiter failed: \(error)")
        }
    }
    
    func testRateLimiterCountRefresh() {
        let middleware = RateLimiter(rate: Rate(100, per: .second))
        let request = getHTTPSRequest()
        
        for _ in 0..<50 {
            do {
                _ = try middleware.respond(to: request, chainingTo: MockResponder())
            } catch {
                XCTFail("Rate limiter failed: \(error)")
                break
            }
        }
        
        var requestsLeft = try! middleware.cache.get("192.168.1.2")?["requestsLeft"]?.int
        XCTAssertEqual(requestsLeft, 50)

        Thread.sleep(forTimeInterval: 1)
        do {
            _ = try middleware.respond(to: request, chainingTo: MockResponder())
        } catch {
            XCTFail("Rate limiter failed: \(error)")
        }
        
        requestsLeft = try! middleware.cache.get("192.168.1.2")?["requestsLeft"]?.int
        XCTAssertEqual(requestsLeft, 99, "Requests left should've reset")
    }
    
    func testSSLEnforcerBasic() {
        let middleware = SSLEnforcer(error: Abort.badRequest, drop: productionDrop)
        let request = getHTTPSRequest()
        
        do {
            _ = try middleware.respond(to: request, chainingTo: MockResponder())
        } catch {
            XCTFail("Request failed: \(error)")
        }
    }
    
    func testSSLEnforcerDenied() {
        let middleware = SSLEnforcer(error: Abort.badRequest, drop: productionDrop)
        let request = getHTTPRequest()
        
        do {
            _ = try middleware.respond(to: request, chainingTo: MockResponder())
            XCTFail("Should've been rejected")
        } catch Abort.badRequest {
            // success
        } catch {
            XCTFail("Request failed: \(error)")
        }
    }
    
    func testSSLEnforcerDoNotEnforce() {
        let middleware = SSLEnforcer(error: Abort.badRequest, drop: developmentDrop)
        let request = getHTTPSRequest()
        
        do {
            _ = try middleware.respond(to: request, chainingTo: MockResponder())
        } catch {
            XCTFail("SSL should not have been enforced for development.")
        }
    }
    
    func testRefreshIntervalValues() {
        let expected: [(Rate.Interval, Double)] = [
            (.second, 1),
            (.minute, 60),
            (.hour, 3_600),
            (.day, 86_400)
        ]
        
        expected.forEach { interval, expected in
            let rate = Rate(1, per: interval)
            XCTAssertEqual(rate.refreshInterval, expected)
        }
    }
}

extension GatekeeperTests {
    var developmentDrop: Droplet {
        return Droplet(environment: .development)
    }
    
    var productionDrop: Droplet {
        return Droplet(environment: .production)
    }

    func getHTTPRequest() -> Request {
        return try! Request(method: .get, uri: "http://localhost:8080/")
    }
    
    func getHTTPSRequest() -> Request {
        return try! Request(
            method: .get,
            uri: URI("https://localhost:8080/"),
            peerAddress: PeerAddress(stream: "192.168.1.2")
        )
    }
}

struct MockResponder: Responder {
    func respond(to request: Request) throws -> Response {
        return "Hello, world".makeResponse()
    }
}
