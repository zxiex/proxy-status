APP := build/ProxyStatus.app
ZIP := build/ProxyStatus.zip
BIN := $(APP)/Contents/MacOS/ProxyStatus
SOURCES := $(wildcard Sources/*.swift)
TARGET := arm64-apple-macos12
RESOURCES := $(APP)/Contents/Resources
ICONS := $(addprefix Resources/,AppIcon.icns proxy-on.png proxy-on@2x.png proxy-off.png proxy-off@2x.png)

.PHONY: build run install dist clean

build: $(BIN)

$(BIN): $(SOURCES) Info.plist $(ICONS)
	mkdir -p $(@D) $(RESOURCES)
	cp Info.plist $(APP)/Contents/Info.plist
	cp $(ICONS) $(RESOURCES)/
	swiftc -O -wmo -swift-version 6 -target $(TARGET) -o $@ $(SOURCES)
	strip -x $@
	codesign --force --sign - $(APP)

run: build
	open $(APP)

install: build
	rm -rf /Applications/ProxyStatus.app
	cp -R $(APP) /Applications/

dist: build
	rm -f $(ZIP)
	ditto -c -k --keepParent $(APP) $(ZIP)
	@echo "Created $(ZIP)"

clean:
	rm -rf build
