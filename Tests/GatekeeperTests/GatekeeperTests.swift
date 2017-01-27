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
        let request = getValidRequest()
        
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
    
    func testSSLEnforcerBasic() {
        let middleware = SSLEnforcer(error: Abort.badRequest, drop: productionDrop)
        let request = getValidRequest()
        
        do {
            _ = try middleware.respond(to: request, chainingTo: MockResponder())
        } catch {
            XCTFail("Request failed: \(error)")
        }
    }
    
    func testSSLEnforcerDenied() {
        let middleware = SSLEnforcer(error: Abort.badRequest, drop: productionDrop)
        let request = getInvalidRequest()
        
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
        let request = getInvalidRequest()
        
        do {
            _ = try middleware.respond(to: request, chainingTo: MockResponder())
        } catch {
            XCTFail("SSL should not have been enforced for development.")
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
    
    func getValidRequest() -> Request {
        return try! Request(
            method: .get,
            uri: URI("https://localhost:8080/"),
            peerAddress: PeerAddress(stream: "192.168.1.2")
        )
    }
    
    func getInvalidRequest() -> Request {
        return try! Request(method: .get, uri: "http://localhost:8080/")
    }
}

struct MockResponder: Responder {
    func respond(to request: Request) throws -> Response {
        return "Hello, world".makeResponse()
    }
}
