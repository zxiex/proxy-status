import Foundation
import SystemConfiguration

/// Reports the active system proxies now and whenever they change.
///
/// Subscribes to `SCDynamicStore` notifications, so it does no work between changes.
@MainActor
final class ProxyMonitor {
    private let onChange: ([ActiveProxy]) -> Void
    private var store: SCDynamicStore?

    init(onChange: @escaping ([ActiveProxy]) -> Void) {
        self.onChange = onChange
    }

    func start() {
        var context = SCDynamicStoreContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        store = SCDynamicStoreCreate(nil, "ProxyStatus" as CFString, { _, _, info in
            MainActor.assumeIsolated {
                Unmanaged<ProxyMonitor>.fromOpaque(info!).takeUnretainedValue().publish()
            }
        }, &context)

        guard let store,
              SCDynamicStoreSetNotificationKeys(store, [SCDynamicStoreKeyCreateProxies(nil)] as CFArray, nil),
              SCDynamicStoreSetDispatchQueue(store, .main)
        else {
            fatalError("Cannot observe proxy settings: \(SCErrorString(SCError()))")
        }
        publish()
    }

    private func publish() {
        let settings = SCDynamicStoreCopyProxies(store) as? [String: Any] ?? [:]
        onChange(activeProxies(in: settings))
    }
}
