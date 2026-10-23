# moh-launcher

MoH Launcher for MoHAA. The window is black, with red controls.

![Launcher](preview.jpg?v=24)

Connect opens `openmohaa.app`. Bots opens `mohbots.app`. The first shortcut is Forte FFA and cannot be changed.

Download [launcher-macos-arm64.zip](https://github.com/pstngh/moh-launcher/releases/download/v2.0/launcher-macos-arm64.zip) (Apple silicon, macOS 15 or later). Unzip `launcher.app` into the game folder, next to `openmohaa.app` and `mohbots.app`.

`./bundle.sh` builds `launcher.app` in the current folder. It needs `rsvg-convert` (`brew install librsvg`).

## Not in the menu

Stock maps left out of the map menu. Add to this list as we find more.

- Destroyed Village (`dm/mohdm2`)
- Omaha Beach (`obj/obj_team3`)
- Remagen (`dm/mohdm3`)
- Snowy Park (`dm/mohdm5`)
- The Crossroads (`dm/mohdm4`)
- The Hunt (`obj/obj_team1`)

