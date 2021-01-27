import Vapor

extension Request {
    var hostname: String? {
        return headers.first(name: .xForwardedFor) ?? remoteAddress?.hostname
    }
}
