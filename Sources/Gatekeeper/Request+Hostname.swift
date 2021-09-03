import Vapor

extension Request {
    var hostname: String? {
        headers.forwarded.first?.for ?? headers.first(name: .xForwardedFor) ?? remoteAddress?.hostname
    }
}
