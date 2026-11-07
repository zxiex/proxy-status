import Foundation

enum ProxyKind: String, CaseIterable, Codable, Sendable {
    case http, https, socks, pac, autoDiscovery

    fileprivate var getCommand: String {
        switch self {
        case .http: "-getwebproxy"
        case .https: "-getsecurewebproxy"
        case .socks: "-getsocksfirewallproxy"
        case .pac: "-getautoproxyurl"
        case .autoDiscovery: "-getproxyautodiscovery"
        }
    }

    fileprivate var setCommand: String {
        switch self {
        case .http: "-setwebproxystate"
        case .https: "-setsecurewebproxystate"
        case .socks: "-setsocksfirewallproxystate"
        case .pac: "-setautoproxystate"
        case .autoDiscovery: "-setproxyautodiscovery"
        }
    }
}

/// One proxy type on one network service, such as HTTP on Wi-Fi.
struct ProxySlot: Codable, Hashable, Sendable {
    let service: String
    let kind: ProxyKind
}

enum ProxySwitchError: LocalizedError {
    case nothingToTurnOff
    case nothingToTurnOn
    case commandFailed(String)

    var errorDescription: String? {
        switch self {
        case .nothingToTurnOff:
            "This proxy isn't set in your network services, so it may be managed by a VPN or profile."
        case .nothingToTurnOn:
            "No proxy server is configured. Add one in System Settings > Network first."
        case .commandFailed(let output):
            output
        }
    }
}

/// Turns system proxies on and off through `networksetup`.
///
/// Turning off remembers which proxies were on, and turning on restores exactly
/// those. With nothing remembered, it enables every proxy with a saved server.
///
/// `@unchecked` because the only non-`Sendable` property, `UserDefaults`, is thread-safe.
struct ProxySwitch: @unchecked Sendable {
    private struct SlotState {
        let slot: ProxySlot
        let isEnabled: Bool
        let hasServer: Bool
    }

    private static let rememberedKey = "rememberedProxies"

    private let tool: String
    private let defaults: UserDefaults

    init(tool: String = "/usr/sbin/networksetup", defaults: UserDefaults = .standard) {
        self.tool = tool
        self.defaults = defaults
    }

    func turnOff() throws {
        let enabled = try readStates().filter(\.isEnabled).map(\.slot)
        guard !enabled.isEmpty else { throw ProxySwitchError.nothingToTurnOff }

        defaults.set(try JSONEncoder().encode(enabled), forKey: Self.rememberedKey)
        try setSlots(enabled, on: false)
    }

    func turnOn() throws {
        let states = try readStates()
        let remembered = rememberedSlots()
        let restorable = states.map(\.slot).filter(remembered.contains)
        let slots = restorable.isEmpty ? states.filter(\.hasServer).map(\.slot) : restorable
        guard !slots.isEmpty else { throw ProxySwitchError.nothingToTurnOn }

        try setSlots(slots, on: true)
    }

    private func rememberedSlots() -> Set<ProxySlot> {
        guard let data = defaults.data(forKey: Self.rememberedKey),
              let slots = try? JSONDecoder().decode([ProxySlot].self, from: data)
        else { return [] }
        return Set(slots)
    }

    private func setSlots(_ slots: [ProxySlot], on: Bool) throws {
        for slot in slots {
            try run(slot.kind.setCommand, slot.service, on ? "on" : "off")
        }
    }

    private func readStates() throws -> [SlotState] {
        try enabledServices().flatMap { service in
            try ProxyKind.allCases.map { kind in
                try readState(of: ProxySlot(service: service, kind: kind))
            }
        }
    }

    /// Lists network services, skipping the header line and disabled services (marked `*`).
    private func enabledServices() throws -> [String] {
        try run("-listallnetworkservices")
            .split(separator: "\n")
            .dropFirst()
            .filter { !$0.hasPrefix("*") }
            .map(String.init)
    }

    private func readState(of slot: ProxySlot) throws -> SlotState {
        let fields = parseFields(try run(slot.kind.getCommand, slot.service))
        let enabledField = slot.kind == .autoDiscovery ? "Auto Proxy Discovery" : "Enabled"
        let server = slot.kind == .pac ? fields["URL"] : fields["Server"]

        return SlotState(
            slot: slot,
            isEnabled: ["Yes", "On"].contains(fields[enabledField]),
            hasServer: server.map { !$0.isEmpty && $0 != "(null)" } ?? false
        )
    }

    /// Parses `Name: value` lines. Values may contain colons, as URLs do.
    private func parseFields(_ output: String) -> [String: String] {
        var fields: [String: String] = [:]
        for line in output.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }
            fields[String(parts[0])] = parts[1].trimmingCharacters(in: .whitespaces)
        }
        return fields
    }

    @discardableResult
    private func run(_ arguments: String...) throws -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        let output = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
        process.waitUntilExit()

        guard process.terminationStatus == 0, !output.contains("** Error") else {
            throw ProxySwitchError.commandFailed(output.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return output
    }
}
