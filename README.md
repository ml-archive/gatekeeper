# Gatekeeper 👮
[![Swift Version](https://img.shields.io/badge/Swift-4.2-brightgreen.svg)](http://swift.org)
[![Vapor Version](https://img.shields.io/badge/Vapor-3-30B6FC.svg)](http://vapor.codes)
[![Circle CI](https://circleci.com/gh/nodes-vapor/gatekeeper/tree/master.svg?style=shield)](https://circleci.com/gh/nodes-vapor/gatekeeper)
[![codebeat badge](https://codebeat.co/badges/35c7b0bb-1662-44ae-b953-ab1d4aaf231f)](https://codebeat.co/projects/github-com-nodes-vapor-gatekeeper-master)
[![codecov](https://codecov.io/gh/nodes-vapor/gatekeeper/branch/master/graph/badge.svg)](https://codecov.io/gh/nodes-vapor/gatekeeper)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=https://github.com/nodes-vapor/gatekeeper)](http://clayallsopp.github.io/readme-score?url=https://github.com/nodes-vapor/gatekeeper)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/gatekeeper/master/LICENSE)

Gatekeeper is a middleware that restricts the number of requests from clients, based on their IP address.
It works by adding the clients IP address to the cache and count how many requests the clients can make during the Gatekeeper's defined lifespan and give back an HTTP 429(Too Many Requests) if the limit has been reached. The number of requests left will be reset when the defined timespan has been reached.

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

**Cache**

You must implement the protocol GateKeeperCache and register it with the application before using GateKeeper

```swift
    app.register(GateKeeperCache.self) { (app: Application) -> GateKeeperCache in
        return MyGateKeeperCache()
    }
```


**For all requests**
in configure.swift:
```swift

// Register providers first
    let gateKeeperConfig = GatekeeperConfig(maxRequests: 10, per: .second)
    app.provider(GatekeeperProvider(config: gateKeeperConfig)(

```

## Credits 🏆

This package is developed and maintained by the Vapor team at [Nodes](https://www.nodesagency.com).
The package owner for this project is [Christian](https://github.com/cweinberger).

## License 📄

This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
