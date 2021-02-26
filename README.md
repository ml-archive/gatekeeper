# Gatekeeper 👮
[![Swift Version](https://img.shields.io/badge/Swift-5.3-brightgreen.svg)](http://swift.org)
[![Vapor Version](https://img.shields.io/badge/Vapor-4-30B6FC.svg)](http://vapor.codes)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/gatekeeper/master/LICENSE)

Gatekeeper is a middleware that restricts the number of requests from clients, based on their IP address **(can be customized)**.
It works by adding the clients identifier to the cache and count how many requests the clients can make during the Gatekeeper's defined lifespan and give back an HTTP 429(Too Many Requests) if the limit has been reached. The number of requests left will be reset when the defined timespan has been reached.

**Please take into consideration that multiple clients can be using the same IP address. eg. public wifi**


## 📦 Installation

Update your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/nodes-vapor/gatekeeper.git", from: "4.0.0"),
```

as well as to your target (e.g. "App"):

```swift
targets: [
    .target(name: "App", dependencies: [..., "Gatekeeper", ...]),
    // ...
]
```

## Getting started 🚀

### Configuration

in configure.swift:
```swift
import Gatekeeper

// [...]

app.caches.use(.memory)
app.gatekeeper.config = .init(maxRequests: 10, per: .second)
```

### Add to routes

You can add the `GatekeeperMiddleware` to specific routes or to all.

**Specific routes**
in routes.swift:
```swift
let protectedRoutes = router.grouped(GatekeeperMiddleware())
protectedRoutes.get("protected/hello") { req in
    return "Protected Hello, World!"
}
```

**For all requests**
in configure.swift:
```swift
// Register middleware
app.middlewares.use(GatekeeperMiddleware())
```

#### Customizing config
By default `GatekeeperMiddleware` uses `app.gatekeeper.config` as its configuration.
However, you can pass a custom configuration to each `GatekeeperMiddleware` type via the initializer
`GatekeeperMiddleware(config:)`. This allows you to set configuration on a per-route basis.

## Key Makers 🔑
By default Gatekeeper uses the client's hostname (IP address) to identify them. This can cause issues where multiple clients are connected from the same network. Therefore, you can customize how Gatekeeper should identify the client by using the `GatekeeperKeyMaker` protocol.

`GatekeeperHostnameKeyMaker` is used by default.

You can configure which key maker Gatekeeper should use in `configure.swift`:
```swift
app.gatekeeper.keyMakers.use(.hostname) // default
```

### Custom key maker
This is an example of a key maker that uses the user's ID to identify them.
```swift
struct UserIDKeyMaker: GatekeeperKeyMaker {
    public func make(for req: Request) -> EventLoopFuture<String> {
        let userID = try req.auth.require(User.self).requireID()        
        return req.eventLoop.future("gatekeeper_" + userID.uuidString)
    }
}
```

```swift
extension Application.Gatekeeper.KeyMakers.Provider {
    public static var userID: Self {
        .init { app in
            app.gatekeeper.keyMakers.use { _ in UserIDKeyMaker() }
        }
    }
}
```
**configure.swift:**
```swift
app.gatekeeper.keyMakers.use(.userID)
```

## Cache 🗄
Gatekeeper uses the same cache as configured by `app.caches.use()` from Vapor, by default.
Therefore it is **important** to set up Vapor's cache if you're using this default behaviour. You can use an in-memory cache for Vapor like so:

**configure.swift**:
```swift
app.cache.use(.memory)
```

### Custom cache
You can override which cache to use by creating your own type that conforms to the `Cache` protocol from Vapor. Use `app.gatekeeper.caches.use()` to configure which cache to use.


## Credits 🏆

This package is developed and maintained by the Vapor team at [Nodes](https://www.nodesagency.com).
The package owner for this project is [Christian](https://github.com/cweinberger).
Special thanks goes to [madsodgaard](https://github.com/madsodgaard) for his work on the Vapor 4 version!

## License 📄

This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
