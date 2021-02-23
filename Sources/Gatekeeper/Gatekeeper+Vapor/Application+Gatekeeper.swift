import Vapor

// MARK: - Application+Gatekeeper
extension Application {
    public struct Gatekeeper {
        private let app: Application
        
        init(app: Application) {
            self.app = app
        }
        
        private final class Storage {
            var config: GatekeeperConfig? = nil
            var makeCache: ((Application) -> Cache)? = nil
            var makeKeyMaker: ((Application) -> GatekeeperKeyMaker)? = nil
        }
        
        private struct Key: StorageKey {
            typealias Value = Storage
        }
        
        private var storage: Storage {
            if app.storage[Key.self] == nil {
                initialize()
            }
            
            return app.storage[Key.self]!
        }
        
        private func initialize() {
            app.storage[Key.self] = Storage()
            app.gatekeeper.caches.use(.default)
            app.gatekeeper.keyMakers.use(.hostname)
        }
        
        /// The default config used for middlewares.
        public var config: GatekeeperConfig {
            get {
                guard let config = storage.config else {
                    fatalError("Gatekeeper not configured, use: app.gatekeeper.config = ...")
                }
                
                return config
            }
            nonmutating set { storage.config = newValue }
        }
    }
    
    public var gatekeeper: Gatekeeper {
        .init(app: self)
    }
}

// MARK: - Gatekeeper+Caches
extension Application.Gatekeeper {
    public struct Caches {
        private let gatekeeper: Application.Gatekeeper
        
        public init(_ gatekeeper: Application.Gatekeeper) {
            self.gatekeeper = gatekeeper
        }
        
        public struct Provider {
            public let run: (Application) -> Void
            
            public init(_ run: @escaping (Application) -> Void) {
                self.run = run
            }
            
            /// A provider that uses the default Vapor cache.
            public static var `default`: Self {
                .init { app in
                    app.gatekeeper.caches.use { $0.cache }
                }
            }
        }
        
        public func use(_ makeCache: @escaping (Application) -> Cache) {
            gatekeeper.storage.makeCache = makeCache
        }
        
        public func use(_ provider: Provider) {
            provider.run(gatekeeper.app)
        }
        
        public var cache: Cache {
            guard let factory = gatekeeper.storage.makeCache else {
                fatalError("Gatekeeper not configured, use: app.gatekeeper.caches.use(...)")
            }
            
            return factory(gatekeeper.app)
        }
    }
    
    public var caches: Caches {
        .init(self)
    }
}

// MARK: - Gatekeeper+Keymakers
extension Application.Gatekeeper {
    public struct KeyMakers {
        private let gatekeeper: Application.Gatekeeper
        
        public init(_ gatekeeper: Application.Gatekeeper) {
            self.gatekeeper = gatekeeper
        }
        
        public struct Provider {
            public let run: (Application) -> Void
            
            public init(_ run: @escaping (Application) -> Void) {
                self.run = run
            }
            
            /// A provider that the request hostname to generate a cache key.
            public static var hostname: Self {
                .init { app in
                    app.gatekeeper.keyMakers.use { _ in GatekeeperHostnameKeyMaker() }
                }
            }
        }
        
        public func use(_ makeKeyMaker: @escaping (Application) -> GatekeeperKeyMaker) {
            gatekeeper.storage.makeKeyMaker = makeKeyMaker
        }
        
        public func use(_ provider: Provider) {
            provider.run(gatekeeper.app)
        }
        
        public var keyMaker: GatekeeperKeyMaker {
            guard let factory = gatekeeper.storage.makeKeyMaker else {
                fatalError("Gatekeeper not configured, use: app.gatekeeper.keyMakers.use(...)")
            }
            
            return factory(gatekeeper.app)
        }
    }
    
    public var keyMakers: KeyMakers {
        .init(self)
    }
}
