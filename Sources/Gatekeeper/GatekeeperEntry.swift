import Vapor

extension Gatekeeper {
    /// A model representing a entry in the cache for a specific client
    public struct Entry: Codable {
        let hostname: String
        var createdAt: Date
        var requestsLeft: Int
    }
}

extension Gatekeeper.Entry {
    func hasExpired(within interval: Double) -> Bool {
        Date().timeIntervalSince1970 - createdAt.timeIntervalSince1970 >= interval
    }
    
    mutating func touch() {
        if requestsLeft > 0 {
            requestsLeft -= 1
        } else {
            requestsLeft = 0
        }
    }
}
