import XCTest
import Vapor
@testable import Gatekeeper

class GatekeeperTests: XCTestCase {

    func testGateKeeper() throws {

        let request = try Request.test(
            gatekeeperConfig: GatekeeperConfig(maxRequests: 10, per: .minute),
            peerName: "::1"
        )

        let gateKeeper = try request.make(Gatekeeper.self)

        for i in 1...11 {
            do {
                _ = try gateKeeper.accessEndpoint(on: request).wait()
                XCTAssertTrue(i <= 10, "ran \(i) times.")
            } catch let error as Abort {
                switch error.status {
                    case .tooManyRequests:
                        //success
                        XCTAssertEqual(i, 11, "Should've failed after the 11th attempt.")
                        break
                    default:
                        XCTFail("Expected too many request: \(error)")
                }
            } catch {
                XCTFail("Caught wrong error: \(error)")
            }
        }
    }
    
    func testGateKeeperNoPeer() throws {

        let request = try Request.test(
            gatekeeperConfig: GatekeeperConfig(maxRequests: 10, per: .minute),
            peerName: nil
        )

        let gateKeeper = try request.make(Gatekeeper.self)

        do {
            _ = try gateKeeper.accessEndpoint(on: request).wait()
            XCTAssertTrue(false, "Gatekeeper should throw")
        } catch let error as Abort {
            switch error.status {
                case .forbidden:
                    //success
                    break
                default:
                    XCTFail("Expected forbidden")
            }
        } catch {
            XCTFail("Rate limiter failed: \(error)")
        }
    }

    func testGateKeeperCountRefresh() throws {

        let request = try Request.test(
            gatekeeperConfig: GatekeeperConfig(maxRequests: 100, per: .second),
            peerName: "192.168.1.2"
        )

        let gateKeeper = try request.make(Gatekeeper.self)

        for _ in 0..<50 {
            do {
                _ = try gateKeeper.accessEndpoint(on: request).wait()
            } catch {
                XCTFail("Rate limiter failed: \(error)")
                break
            }
        }

        let cache = try request.make(KeyedCache.self)
        var entry = try! cache.get("gatekeeper_192.168.1.2", as: Gatekeeper.Entry.self).wait()
        XCTAssertEqual(entry!.requestsLeft, 50)

        Thread.sleep(forTimeInterval: 1)
        do {
            _ = try gateKeeper.accessEndpoint(on: request).wait()
        } catch {
            XCTFail("Rate limiter failed: \(error)")
        }

        entry = try! cache.get("gatekeeper_192.168.1.2", as: Gatekeeper.Entry.self).wait()
        XCTAssertEqual(entry!.requestsLeft, 99, "Requests left should've reset")
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
}
