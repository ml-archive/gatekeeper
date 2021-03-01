import Vapor

extension Request {
    var hostname: String? {
        headers.first(name: .xForwardedFor) ?? remoteAddress?.hostname
    }
}
