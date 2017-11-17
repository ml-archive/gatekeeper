# Gatekeeper 👮
[![Swift Version](https://img.shields.io/badge/Swift-3.1-brightgreen.svg)](http://swift.org)
[![Vapor Version](https://img.shields.io/badge/Vapor-2-F6CBCA.svg)](http://vapor.codes)
[![Linux Build Status](https://img.shields.io/circleci/project/github/nodes-vapor/gatekeeper.svg?label=Linux)](https://circleci.com/gh/nodes-vapor/gatekeeper)
[![macOS Build Status](https://img.shields.io/travis/nodes-vapor/gatekeeper.svg?label=macOS)](https://travis-ci.org/nodes-vapor/gatekeeper)
[![codebeat badge](https://codebeat.co/badges/52c2f960-625c-4a63-ae63-52a24d747da1)](https://codebeat.co/projects/github-com-nodes-vapor-gatekeeper)
[![codecov](https://codecov.io/gh/nodes-vapor/gatekeeper/branch/master/graph/badge.svg)](https://codecov.io/gh/nodes-vapor/gatekeeper)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=https://github.com/nodes-vapor/gatekeeper)](http://clayallsopp.github.io/readme-score?url=https://github.com/nodes-vapor/gatekeeper)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/gatekeeper/master/LICENSE)

Gatekeeper is a middleware that restricts the number of requests from clients, based on their IP address.
It works by adding the clients IP address to the cache and count how many requests the clients can make during the Gatekeepers defined lifespan and give back an HTTP 429(Too Many Requests) if the limit has been reached. The number of requests left will be reset when the defined timespan has been reached

**Please take into consideration that multiple clients can be using the same IP address. eg. public wifi**


## 📦 Installation

Update your `Package.swift` file.
```swift
.Package(url: "https://github.com/nodes-vapor/gatekeeper", majorVersion: 0)
```


## Getting started 🚀

`Gatekeeper` has two configurable fields: the maximum rate and the cache to use. If you don't supply your own cache the limiter will create its own, in-memory cache.

```swift
let gatekeeper = GateKeeper(rate: Rate(10, per: .minute))
```

### Adding middleware
You can add the middleware either globally or to a route group.

#### Adding Middleware Globally

#### `Sources/App/Config+Setup.swift`
```swift
import Gatekeeper
```

```swift
public func setup() throws {
    // ...

    addConfigurable(middleware: Gatekeeper(rate: Rate(10, per: .minute)), name: "gatekeeper")
}
```

#### `Config/droplet.json`

Add `gatekeeper` to the middleware array

```json
"middleware": [
    "error",
    "date",
    "file",
    "gatekeeper"
]
```


#### Adding Middleware to a Route Group

```Swift
let gatekeeper = Gatekeeper(rate: Rate(10, per: .minute))

drop.group(gatekeeper) { group in
   // Routes
}
```


### The `Rate.Interval` enumeration

The currently implemented intervals are:
```swift
case .second
case .minute
case .hour
case .day
```

## Credits 🏆

This package is developed and maintained by the Vapor team at [Nodes](https://www.nodes.dk).
The package owner for this project is [Tom](https://github.com/tomserowka).


## License 📄

This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
