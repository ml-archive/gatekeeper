import XCTest

extension GatekeeperTests {
    static let __allTests = [
        ("testGateKeeper", testGateKeeper),
        ("testGateKeeperNoPeer", testGateKeeperNoPeer),
        ("testGateKeeperCountRefresh", testGateKeeperCountRefresh),
        ("testRefreshIntervalValues", testRefreshIntervalValues),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(GatekeeperTests.__allTests),
    ]
}
#endif
