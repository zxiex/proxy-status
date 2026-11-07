# ProxyStatus

A minimal macOS menu bar indicator showing whether a system proxy is enabled.

- **Proxy on:** green globe icon. The menu lists each enabled proxy.
- **Proxy off:** gray globe icon.

It checks HTTP, HTTPS, SOCKS, PAC, and auto-discovery (WPAD) settings. Updates
are event-driven through `SCDynamicStore`, so nothing polls in the background.

It reads the proxy configuration only: it doesn't test whether the proxy is
reachable, and it can't see tunnels (VPN or TUN mode) or per-app proxies.

## Turning the proxy on or off

Use **Turn Proxy Off** or **Turn Proxy On** in the menu. This changes the system
settings through `networksetup`, on all enabled network services, and usually
requires an administrator account.

- **Off** remembers which proxies were on, then disables them.
- **On** restores exactly those. If nothing is remembered, it enables every
  proxy that has a saved server.

A proxy must be set up in System Settings > Network first. Proxies set by a VPN
or configuration profile can't be turned off here, and proxy apps may re-enable
their own settings.

## Build

Runs on Apple Silicon Macs with macOS 12 or later. Building requires the Xcode
Command Line Tools.

```sh
make run       # build and launch
make install   # copy to /Applications
make dist      # zip the app to build/ProxyStatus.zip
make clean
```

## Install on another Mac

Run `make dist`, copy `build/ProxyStatus.zip` to the other Mac, unzip it, and
move `ProxyStatus.app` to `/Applications`.

The app isn't signed with a Developer ID, so macOS will block the first launch.
Try to open it once, then click **Open Anyway** in System Settings > Privacy &
Security, or run:

```sh
xattr -dr com.apple.quarantine /Applications/ProxyStatus.app
```

To start it at login, add it under System Settings > General > Login Items.

## License

[MIT](LICENSE)
