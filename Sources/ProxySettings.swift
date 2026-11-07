import Foundation
import SystemConfiguration

/// A proxy that is currently enabled in the system settings.
struct ActiveProxy: Equatable {
    let kind: String
    let endpoint: String
}

/// Returns the enabled proxies in a dictionary from `SCDynamicStoreCopyProxies`.
func activeProxies(in settings: [String: Any]) -> [ActiveProxy] {
    func isEnabled(_ key: CFString) -> Bool {
        (settings[key as String] as? Int ?? 0) != 0
    }

    func server(kind: String, enable: CFString, host: CFString, port: CFString) -> ActiveProxy? {
        guard isEnabled(enable), let host = settings[host as String] as? String else { return nil }
        let endpoint = (settings[port as String] as? Int).map { "\(host):\($0)" } ?? host
        return ActiveProxy(kind: kind, endpoint: endpoint)
    }

    var proxies = [
        server(kind: "HTTP", enable: kSCPropNetProxiesHTTPEnable,
               host: kSCPropNetProxiesHTTPProxy, port: kSCPropNetProxiesHTTPPort),
        server(kind: "HTTPS", enable: kSCPropNetProxiesHTTPSEnable,
               host: kSCPropNetProxiesHTTPSProxy, port: kSCPropNetProxiesHTTPSPort),
        server(kind: "SOCKS", enable: kSCPropNetProxiesSOCKSEnable,
               host: kSCPropNetProxiesSOCKSProxy, port: kSCPropNetProxiesSOCKSPort),
    ].compactMap { $0 }

    if isEnabled(kSCPropNetProxiesProxyAutoConfigEnable) {
        let url = settings[kSCPropNetProxiesProxyAutoConfigURLString as String] as? String
        proxies.append(ActiveProxy(kind: "PAC", endpoint: url ?? "Configured"))
    }
    if isEnabled(kSCPropNetProxiesProxyAutoDiscoveryEnable) {
        proxies.append(ActiveProxy(kind: "Auto-discovery", endpoint: "WPAD"))
    }
    return proxies
}
