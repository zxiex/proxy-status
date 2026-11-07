import AppKit

/// Shows the proxy state as a menu bar icon, with details and a toggle in its menu.
@MainActor
final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let proxySwitch = ProxySwitch()
    private var monitor: ProxyMonitor?
    private var isActive = false
    private var isSwitching = false

    override init() {
        super.init()
        monitor = ProxyMonitor { [weak self] proxies in self?.render(proxies) }
        monitor?.start()
    }

    private func render(_ proxies: [ActiveProxy]) {
        isActive = !proxies.isEmpty
        let title = isActive ? "Proxy On" : "Proxy Off"

        if let button = statusItem.button {
            let image = NSImage(named: isActive ? "proxy-on" : "proxy-off")
            image?.accessibilityDescription = title
            button.image = image
            button.toolTip = title
        }
        statusItem.menu = makeMenu(title: title, proxies: proxies)
    }

    private func makeMenu(title: String, proxies: [ActiveProxy]) -> NSMenu {
        let menu = NSMenu()
        menu.addItem(withTitle: title, action: nil, keyEquivalent: "")
        for proxy in proxies {
            menu.addItem(withTitle: "\(proxy.kind): \(proxy.endpoint)", action: nil, keyEquivalent: "")
        }
        menu.addItem(.separator())

        let toggle = menu.addItem(
            withTitle: isActive ? "Turn Proxy Off" : "Turn Proxy On",
            action: #selector(toggleProxy),
            keyEquivalent: ""
        )
        toggle.target = self

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate), keyEquivalent: "q")
        return menu
    }

    /// Runs off the main thread because `networksetup` can be slow. On success,
    /// the icon updates through `ProxyMonitor` when the system settings change.
    @objc private func toggleProxy() {
        guard !isSwitching else { return }
        isSwitching = true

        let proxySwitch = proxySwitch
        let turnOff = isActive
        Task {
            let failure = await Task.detached {
                do {
                    try turnOff ? proxySwitch.turnOff() : proxySwitch.turnOn()
                    return nil as String?
                } catch {
                    return error.localizedDescription
                }
            }.value

            isSwitching = false
            if let failure { showAlert(failure, turningOff: turnOff) }
        }
    }

    private func showAlert(_ message: String, turningOff: Bool) {
        let alert = NSAlert()
        alert.messageText = turningOff ? "Couldn't Turn Proxy Off" : "Couldn't Turn Proxy On"
        alert.informativeText = message
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
}
