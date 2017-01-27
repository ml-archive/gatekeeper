import HTTP
import Cache
import Vapor
import Foundation

public struct Rate {
    public enum Interval {
        case second
        case minute
        case hour
        case day
    }
    
    public let limit: Int
    public let interval: Interval
    
    public init(_ limit: Int, per interval: Interval) {
        self.limit = limit
        self.interval = interval
    }
    
    internal var refreshInterval: Double {
        switch interval {
        case .second:
            return 1.0
        case .minute:
            return 60.0
        case .hour:
            return 3_600.0
        case .day:
            return 86_400.0
        }
    }
}

public struct RateLimiter: Middleware {
    private var cache: CacheProtocol
    
    private let limit: Int
    private let refreshInterval: Double
    
    public init(rate: Rate, cache: CacheProtocol = MemoryCache()) {
        self.cache = cache
        self.limit = rate.limit
        self.refreshInterval = rate.refreshInterval
    }
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        guard let peer = request.peerAddress?.address() else {
            throw Abort.custom(status: .forbidden, message: "Unable to verify peer.")
        }
        
        var entry = try cache.get(peer)
        var createdAt = entry?["createdAt"]?.double ?? Date().timeIntervalSince1970
        var requestsLeft = entry?["requestsLeft"]?.int ?? limit
        
        let now = Date().timeIntervalSince1970
        if now - createdAt >= refreshInterval {
            createdAt = now
            requestsLeft = limit
        }
        
        defer {
            do {
                try cache.set(peer, Node(node: [
                    "createdAt": createdAt,
                    "requestsLeft": requestsLeft
                    ]))
            } catch {
                print("WARNING: cache failed: \(error)")
            }
        }
        
        requestsLeft -= 1
        guard requestsLeft >= 0 else {
            throw Abort.custom(status: .tooManyRequests, message: "Slow down.")
        }
        
        let response = try next.respond(to: request)
        return response
    }
}
