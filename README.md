<div align="center">

# ProxyStatus

**A lightweight, native macOS menu bar utility for monitoring and toggling system proxy settings in real time.**

[![Build and Release](https://github.com/zxiex/proxy-status/actions/workflows/release.yml/badge.svg)](https://github.com/zxiex/proxy-status/actions/workflows/release.yml)
[![macOS](https://img.shields.io/badge/macOS-12%2B-black?logo=apple)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

</div>

ProxyStatus lives quietly in your macOS menu bar, showing whether the system proxy is enabled. Click the icon to inspect your proxy configuration or toggle it on and off.

**No background polling. No external dependencies. Just a simple proxy indicator.**

## Features

- **At-a-glance status** — A colored menu bar icon indicates whether the system proxy is enabled.
- **Real-time updates** — Uses macOS `SCDynamicStore` notifications to detect proxy configuration changes without polling.
- **Multiple proxy types** — Detects HTTP, HTTPS, SOCKS, PAC, and automatic proxy discovery (WPAD).
- **One-click toggle** — Enable or disable system proxies directly from the menu bar.
- **Restore settings** — Remembers previously enabled proxy configurations when toggling.
- **Native and lightweight** — Built with Swift and AppKit, with no third-party dependencies.

## Proxy Status

ProxyStatus uses a simple color-coded indicator in the macOS menu bar.

| Proxy Enabled | Proxy Disabled |
|:---:|:---:|
| <img src="Resources/proxy-on.png" width="48" alt="Proxy enabled"> | <img src="Resources/proxy-off.png" width="48" alt="Proxy disabled"> |
| Green — Proxy enabled | Gray — Proxy disabled |

The indicator updates automatically when system proxy settings change, including changes made outside ProxyStatus.

## Installation

### Download

1. Download the latest `ProxyStatus.zip` from [GitHub Releases](https://github.com/zxiex/proxy-status/releases).
2. Extract the archive.
3. Move `ProxyStatus.app` to `/Applications`.
4. Launch ProxyStatus.

> **Note:** ProxyStatus is not currently signed or notarized with an Apple Developer ID. macOS Gatekeeper may block it from opening normally. If you trust the downloaded application, go to **System Settings → Privacy & Security → Open Anyway**.

### Build from Source

Requires macOS 12 or later and the Xcode Command Line Tools.

```bash
git clone https://github.com/zxiex/proxy-status.git
cd proxy-status

make
make run
```

To install locally:

```bash
make install
```

To create a distributable ZIP:

```bash
make dist
```

## Usage

ProxyStatus runs entirely in the macOS menu bar without opening a separate application window.

Click the menu bar icon to:

- View the current system proxy configuration.
- Enable or disable configured proxies.
- Open macOS Network Settings.
- Quit ProxyStatus.

ProxyStatus monitors system configuration changes automatically, so the displayed status stays synchronized with macOS proxy settings.

## How It Works

ProxyStatus uses native macOS frameworks:

| Component | Purpose |
|---|---|
| **SystemConfiguration** | Reads system proxy settings |
| **SCDynamicStore** | Receives notifications when proxy settings change |
| **AppKit** | Provides the native menu bar interface |
| **networksetup** | Changes system proxy settings |

Unlike polling-based utilities, ProxyStatus listens for system configuration notifications and updates only when necessary, minimizing background CPU activity.

> **Important:** ProxyStatus reports system proxy configuration, not actual network traffic. An enabled proxy does not necessarily mean the proxy server is reachable or that every application routes traffic through it.

## Requirements

- macOS 12 Monterey or later
- Apple Silicon (ARM64)
- Xcode Command Line Tools (for building from source only)

## Development

ProxyStatus uses a simple Makefile-based build system without requiring an Xcode project.

```bash
make          # Build the application
make run      # Build and launch
make install  # Install locally
make dist     # Create a distributable ZIP
make clean    # Remove build artifacts
```

### Continuous Integration

GitHub Actions automatically builds ProxyStatus on pushes and pull requests.

Pushing a version tag triggers a release build and publishes a downloadable ZIP to GitHub Releases.

```bash
git tag v0.1.0
git push origin v0.1.0
```

## License

ProxyStatus is released under the MIT License. See [LICENSE](LICENSE) for details.
