import Vapor

public struct GatekeeperConfig {

    public enum Interval {
        case second
        case minute
        case hour
        case day
    }

    public let limit: Int
    public let interval: Interval

    public init(maxRequests limit: Int, per interval: Interval) {
        self.limit = limit
        self.interval = interval
    }

    internal var refreshInterval: Double {
        switch interval {
        case .second:
            return 1
        case .minute:
            return 60
        case .hour:
            return 3_600
        case .day:
            return 86_400
        }
    }
}
