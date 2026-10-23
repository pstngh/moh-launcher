# moh-launcher

MoH Launcher for MoHAA. The window is black, with red controls.

![Launcher](preview.jpg?v=8)

Connect opens `openmohaa.app`. Play opens `mohbots.app`. The first shortcut is Forte FFA and cannot be changed.

Download [launcher-macos-arm64.zip](https://github.com/pstngh/moh-launcher/releases/download/v2.0/launcher-macos-arm64.zip) (Apple silicon, macOS 15 or later). Unzip `launcher.app` into the game folder, next to `openmohaa.app` and `mohbots.app`.

`./bundle.sh` builds `launcher.app` in the current folder. It needs `rsvg-convert` (`brew install librsvg`).
