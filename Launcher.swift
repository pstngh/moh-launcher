// launcher.app: joins a server or starts a local bot match.
//
// It sits in the game folder next to the game. Connect starts openmohaa.app.
// Bots starts mohbots.app. Settings are kept in launcher.cfg beside it.
// bundle.sh builds it.

import Foundation

// MARK: - Settings

/// Maps offered for bot matches. The path is what the game loads. The name
/// is what the menu shows. Spearhead also loads the Allied Assault maps,
/// and Breakthrough loads both, so each list starts with its own.
let aaMaps = [
    "dm/downladder", "dm/brownffa", "dm/vents", "dm/flag", "dm/main", "dm/alpha", "dm/crnodoors",
    "dm/mohdm1", "dm/mohdm6", "dm/mohdm7", "obj/obj_team2", "obj/obj_team4",
]
let shMaps = [
    "dm/MP_Bahnhof_DM", "dm/MP_Bazaar_DM", "dm/MP_Brest_DM", "dm/MP_Gewitter_DM", "dm/MP_Holland_DM",
    "dm/MP_Malta_DM", "dm/MP_Stadt_DM", "dm/MP_Unterseite_DM", "dm/MP_Verschneit_DM",
    "obj/MP_Ardennes_TOW", "obj/MP_Berlin_TOW", "obj/MP_Druckkammern_TOW", "obj/MP_Flughafen_TOW",
]
let btMaps = [
    "obj/MP_BizerteFort_OBJ", "obj/MP_Bologna_OBJ", "obj/MP_Castello_OBJ", "obj/MP_Palermo_OBJ",
    "obj/MP_Kasserine_TOW", "obj/MP_MonteBattaglia_TOW", "obj/MP_MonteCassino_TOW",
    "lib/MP_Anzio_LIB", "lib/MP_BizerteHarbor_LIB", "lib/MP_Ship_LIB", "lib/MP_Tunisia_LIB",
]

let mapNames = [
    "dm/downladder": "V2 - Down Ladder",
    "dm/brownffa": "Bridge - Brown Door",
    "dm/vents": "V2 - Vent Room",
    "dm/flag": "V2 - Flag Room",
    "dm/main": "V2 - Up Main",
    "dm/alpha": "V2 - Alpha",
    "dm/crnodoors": "V2 - Control Room",
    "dm/mohdm1": "Southern France",
    "dm/mohdm6": "Stalingrad",
    "dm/mohdm7": "Algiers",
    "obj/obj_team2": "V2 Rocket Facility",
    "obj/obj_team4": "The Bridge",
    "dm/MP_Bahnhof_DM": "Bahnhof",
    "dm/MP_Bazaar_DM": "Bazaar",
    "dm/MP_Brest_DM": "Brest",
    "dm/MP_Gewitter_DM": "Gewitter",
    "dm/MP_Holland_DM": "Holland",
    "dm/MP_Malta_DM": "Malta",
    "dm/MP_Stadt_DM": "Stadt",
    "dm/MP_Unterseite_DM": "Unterseite",
    "dm/MP_Verschneit_DM": "Verschneit",
    "obj/MP_Ardennes_TOW": "Ardennes",
    "obj/MP_Berlin_TOW": "Berlin",
    "obj/MP_Druckkammern_TOW": "Druckkammern",
    "obj/MP_Flughafen_TOW": "Flughafen",
    "obj/MP_BizerteFort_OBJ": "Bizerte Fort",
    "obj/MP_Bologna_OBJ": "Bologna",
    "obj/MP_Castello_OBJ": "Castello",
    "obj/MP_Palermo_OBJ": "Palermo",
    "obj/MP_Kasserine_TOW": "Kasserine",
    "obj/MP_MonteBattaglia_TOW": "Monte Battaglia",
    "obj/MP_MonteCassino_TOW": "Monte Cassino",
    "lib/MP_Anzio_LIB": "Anzio",
    "lib/MP_BizerteHarbor_LIB": "Bizerte Harbor",
    "lib/MP_Ship_LIB": "Ship",
    "lib/MP_Tunisia_LIB": "Tunisia",
]

func mapName(_ path: String) -> String {
    mapNames[path] ?? path
}

func maps(for game: Int) -> [String] {
    let paths: [String]
    switch game {
    case 0: paths = aaMaps
    case 1: paths = shMaps + aaMaps
    default: paths = btMaps + shMaps + aaMaps
    }
    return paths.sorted {
        mapName($0).localizedCaseInsensitiveCompare(mapName($1)) == .orderedAscending
    }
}

let resolutions = [
    "800x600", "960x720", "1024x768", "1152x864", "1280x720", "1280x960",
    "1344x1008", "1600x1200", "1920x1080",
]

/// Width and height of a resolution, or 1920x1080 when the text is not one.
func pixelSize(_ resolution: String) -> (width: Int, height: Int) {
    let parts = resolution.split(separator: "x")
    guard parts.count == 2, let width = Int(parts[0]), let height = Int(parts[1]), width > 0, height > 0 else {
        return (1920, 1080)
    }
    return (width, height)
}

/// The previous launcher saved the resolution as an index into this list.
let oldResolutions = [
    "800x600", "960x720", "1024x768", "1152x864", "1280x720", "1280x1024",
    "1600x1200", "1920x1080", "1280x960", "1344x1008",
]

let botTeams = ["auto", "allies", "axis"]  // g_bot_team values
let maxBots = 62  // 64 clients minus the two player slots of a bot match
let shortcutCount = 4

/// The first shortcut is built in. Loading and saving cannot change it.
let forte = Shortcut(name: "Forte FFA", address: "151.80.234.90:12203")

/// com_target_game values 0, 1 and 2. The icon is a PNG built into the app.
let games = [
    ("game-aa", "Allied Assault"),
    ("game-sh", "Spearhead"),
    ("game-bt", "Breakthrough"),
]

/// A named server with the passwords that belong to it. A slot without a
/// name is empty.
struct Shortcut: Equatable {
    var name = ""
    var address = ""
    var password = ""
    var rcon = ""
}

struct Config: Equatable {
    var game = 0  // com_target_game of bot matches: 0 Allied Assault, 1 Spearhead, 2 Breakthrough
    var name = ""
    var address = ""
    var password = ""
    var rcon = ""
    var shortcuts = [forte] + Array(repeating: Shortcut(), count: shortcutCount - 1)
    var gametype = 1  // 1 free-for-all, 2 team match, 4 objective
    var map = aaMaps[0]
    var bots = 3
    var botTeam = "auto"
    var health = 100
    var runSpeed = Config.runSpeed(for: 0)
    var infiniteAmmo = true
    var painAnims = true
    var fullscreen = true
    var resolution = "1920x1080"
    var crosshairLength = Config.crosshairDefaults.length
    var crosshairGap = Config.crosshairDefaults.gap
    var crosshairThickness = Config.crosshairDefaults.thickness
    var crosshairColor = Config.crosshairDefaults.color

    static let crosshairDefaults = (length: 9, gap: 4, thickness: 2, color: "FFFFFF")
    static let crosshairLengths = 2...32
    static let crosshairGaps = 1...20
    static let crosshairThicknesses = 1...8
    static let crosshairColors: [(name: String, hex: String)] = [
        ("Green", "00FF00"), ("Cyan", "00FFFF"), ("Yellow", "FFFF00"), ("Red", "FF0000"),
        ("Blue", "0000FF"), ("White", "FFFFFF"), ("Pink", "FF00FF"),
    ]

    static func runSpeed(for game: Int) -> Int {
        game == 0 ? 250 : 287
    }

    /// 250 is Allied Assault and 287 is Spearhead and Breakthrough. The
    /// others sit between those two.
    static let runSpeeds = [250, 255, 260, 265, 270, 275, 280, 287]

    static func nearestSpeed(_ speed: Int) -> Int {
        runSpeeds.min { abs($0 - speed) < abs($1 - speed) } ?? runSpeeds[0]
    }

    /// 250 is Allied Assault. 287 is Spearhead, and Breakthrough uses it too.
    static func runSpeedLabel(_ speed: Int) -> String {
        switch speed {
        case 250: return "250 AA"
        case 287: return "287 SH"
        default: return "\(speed) Runspeed"
        }
    }

    /// One of the named crosshair colors, or white.
    static func color(_ value: String) -> String {
        let hex = (value.hasPrefix("#") ? String(value.dropFirst()) : value).uppercased()
        return crosshairColors.contains { $0.hex == hex } ? hex : crosshairDefaults.color
    }

    var trimmedAddress: String {
        address.trimmingCharacters(in: .whitespaces)
    }

    /// The shortcut saved for the typed address, if any.
    var shortcutIndex: Int? {
        let address = trimmedAddress
        return address.isEmpty ? nil : shortcuts.firstIndex { !$0.name.isEmpty && $0.address == address }
    }

    /// A finished address that matches a shortcut uses that shortcut's
    /// passwords. A partial address leaves whatever is already typed.
    mutating func addressChanged() {
        guard let index = shortcutIndex else { return }
        password = shortcuts[index].password
        rcon = shortcuts[index].rcon
    }

    /// The run speed follows the game, and a map the new game cannot load
    /// gives way to its first map.
    mutating func gameChanged() {
        runSpeed = Config.runSpeed(for: game)
        if !maps(for: game).contains(map) {
            map = maps(for: game)[0]
        }
    }

    mutating func applyShortcut(_ index: Int) {
        address = shortcuts[index].address
        password = shortcuts[index].password
        rcon = shortcuts[index].rcon
    }

    /// A server has one shortcut, so saving it in a slot clears any other
    /// slot with the same address.
    mutating func saveShortcut(_ index: Int, name: String) {
        guard index != 0 else { return }
        let name = name.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
            for other in shortcuts.indices where other != 0 && other != index && shortcuts[other].address == trimmedAddress {
                shortcuts[other] = Shortcut()
            }
            shortcuts[index] = Shortcut(name: name, address: trimmedAddress, password: password, rcon: rcon)
        }
    }

    /// Keeps passwords edited before connecting in the shortcut of that server.
    mutating func rememberPasswords() {
        if let index = shortcutIndex, index != 0 {
            shortcuts[index].password = password
            shortcuts[index].rcon = rcon
        }
    }

    // MARK: Launch arguments

    /// Arguments shared by Connect and Play. The engine keeps configs and
    /// other user data in the game folder by itself.
    func commonArgs() -> [String] {
        let size = pixelSize(resolution)
        var args: [String] = []
        if !name.isEmpty {
            args += set("name", name)
        }
        args += set("cl_playintro", 0)
        args += set("r_fullscreen", fullscreen)
        args += set("r_mode", -1) + set("r_customwidth", size.width) + set("r_customheight", size.height)
        args += set("cg_crosshair_length", crosshairLength) + set("cg_crosshair_gap", crosshairGap)
        args += set("cg_crosshair_thickness", crosshairThickness) + set("cg_crosshair_color", crosshairColor)
        return args
    }

    /// Connect always starts Allied Assault.
    func connectArgs() -> [String] {
        var args = commonArgs() + set("com_target_game", 0)
        if !password.isEmpty {
            args += set("password", password)
        }
        if !rcon.isEmpty {
            args += set("rconPassword", rcon)
        }
        if !trimmedAddress.isEmpty {
            args += ["+connect", trimmedAddress]
        }
        return args
    }

    func playArgs() -> [String] {
        // Rockets and landmines are left out, and the expansions keep the
        // old sniper rifle and give the shotgun instead of the Kar98 mortar.
        var dmflags = 1 << 26 | 1 << 28
        if game != 0 {
            dmflags |= 1 << 19 | 1 << 20
        }
        if infiniteAmmo {
            dmflags |= 1 << 14
        }

        var args = commonArgs() + set("com_target_game", game)
        args += set("g_gametype", gametype)
        args += set("dmflags", dmflags)
        args += set("fraglimit", 0)
        // More than one slot keeps the loading screen from waiting for a click.
        args += set("sv_maxclients", 2)
        args += set("sv_maxbots", bots) + set("sv_numbots", bots) + set("g_bot_team", botTeam)
        args += set("sv_gamespy", 0)
        args += set("g_playerdmhealth", health)
        args += set("sv_runspeed", runSpeed)
        args += set("g_painanims", painAnims)
        // devmap keeps cheats on, and thereisnomonkey stops the first cheat
        // command from turning them off again.
        args += set("thereisnomonkey", 1)
        return args + ["+devmap", map]
    }

    private func set(_ cvar: String, _ value: String) -> [String] {
        ["+set", cvar, value]
    }

    private func set(_ cvar: String, _ value: Int) -> [String] {
        set(cvar, String(value))
    }

    private func set(_ cvar: String, _ value: Bool) -> [String] {
        set(cvar, value ? "1" : "0")
    }

    // MARK: Storage

    /// Reads launcher.cfg lines of key=value, keeping defaults for anything
    /// missing or out of range.
    init(text: String) {
        var values: [String: String] = [:]
        for line in text.split(whereSeparator: \.isNewline) {
            if let equals = line.firstIndex(of: "=") {
                values[String(line[..<equals])] = String(line[line.index(after: equals)...])
            }
        }
        func number(_ key: String, _ range: ClosedRange<Int>, _ fallback: Int) -> Int {
            Int(values[key] ?? "").map { min(max($0, range.lowerBound), range.upperBound) } ?? fallback
        }
        func choice(_ key: String, _ range: ClosedRange<Int>, _ fallback: Int) -> Int {
            Int(values[key] ?? "").flatMap { range.contains($0) ? $0 : nil } ?? fallback
        }
        func flag(_ key: String, _ fallback: Bool) -> Bool {
            values[key].map { $0 != "0" } ?? fallback
        }

        game = choice("game", 0...2, game)
        name = values["nickname"] ?? name
        address = values["ip"] ?? address
        password = values["password"] ?? password
        rcon = values["rcon"] ?? rcon
        for index in shortcuts.indices where index != 0 {
            // The first lean launcher saved servers without a name.
            let address = values["bookmark_ip_\(index)"] ?? ""
            let name = values["bookmark_name_\(index)"] ?? address
            if !name.isEmpty {
                shortcuts[index] = Shortcut(
                    name: name, address: address.trimmingCharacters(in: .whitespaces),
                    password: values["bookmark_pass_\(index)"] ?? "", rcon: values["bookmark_rcon_\(index)"] ?? ""
                )
            }
        }
        shortcuts[0] = forte
        if let saved = Int(values["bot_game_type"] ?? ""), [1, 2, 4].contains(saved) {
            gametype = saved
        }
        map = values["bot_map"].flatMap { maps(for: game).contains($0) ? $0 : nil } ?? maps(for: game)[0]
        bots = number("bot_count", 1...maxBots, bots)
        botTeam = values["bot_team"].flatMap { botTeams.contains($0) ? $0 : nil } ?? botTeam
        health = number("player_health", 1...1000, health)
        runSpeed = Config.nearestSpeed(Int(values["run_speed"] ?? "") ?? Config.runSpeed(for: game))
        infiniteAmmo = flag("infinite_ammo", infiniteAmmo)
        painAnims = flag("pain_anims", painAnims)
        fullscreen = flag("fullscreen_enabled", fullscreen)
        let oldResolution = choice("resolution_index", 0...oldResolutions.count - 1, -1)
        resolution = (values["resolution"] ?? (oldResolution < 0 ? nil : oldResolutions[oldResolution]))
            .flatMap { resolutions.contains($0) ? $0 : nil } ?? resolution
        crosshairLength = number("crosshair_length", Config.crosshairLengths, crosshairLength)
        crosshairGap = number("crosshair_gap", Config.crosshairGaps, crosshairGap)
        crosshairThickness = number("crosshair_thickness", Config.crosshairThicknesses, crosshairThickness)
        crosshairColor = values["crosshair_color"].map(Config.color) ?? crosshairColor
    }

    var text: String {
        var lines = [
            line("game", game), line("nickname", name), line("ip", address), line("password", password), line("rcon", rcon),
            line("bot_game_type", gametype), line("bot_map", map), line("bot_count", bots), line("bot_team", botTeam),
            line("player_health", health), line("run_speed", runSpeed), line("infinite_ammo", infiniteAmmo ? 1 : 0),
            line("pain_anims", painAnims ? 1 : 0),
            line("fullscreen_enabled", fullscreen ? 1 : 0), line("resolution", resolution),
            line("crosshair_length", crosshairLength), line("crosshair_gap", crosshairGap),
            line("crosshair_thickness", crosshairThickness), line("crosshair_color", crosshairColor),
        ]
        for (index, shortcut) in shortcuts.enumerated() where index != 0 && !shortcut.name.isEmpty {
            lines += [
                line("bookmark_name_\(index)", shortcut.name), line("bookmark_ip_\(index)", shortcut.address),
                line("bookmark_pass_\(index)", shortcut.password), line("bookmark_rcon_\(index)", shortcut.rcon),
            ]
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// One setting. A value cannot contain a newline, or the next load would
    /// read the rest of it as further settings.
    private func line(_ key: String, _ value: String) -> String {
        "\(key)=\(value.filter { !$0.isNewline })"
    }

    private func line(_ key: String, _ value: Int) -> String {
        line(key, String(value))
    }
}

/// The engine joins its arguments into one command line, where "+" starts a
/// command, ";" ends one, a quote or "//" or "/*" swallows the rest, and
/// userinfo refuses "\", so typed values may contain none of them.
func isSafe(_ value: String) -> Bool {
    !value.contains(where: \.isNewline) && !["+", ";", "\"", "//", "/*", "\\"].contains { value.contains($0) }
}

// MARK: - Game files

/// MD5 of the retail pak files, by game folder.
let retailPaks = [
    "main/pak0.pk3": "26d6c5383a2318864549f6e625acde4d",
    "main/pak1.pk3": "82cd6260d3d84beceb6b0866f329a1cf",
    "main/pak2.pk3": "1e2e77461a03f02a9878508a7e035c2f",
    "main/pak3.pk3": "08ae9d7ee5bb25bf9115fbe4bd071714",
    "main/pak4.pk3": "fff8f0f1e6f9c2a6f1fb0dc194c5822b",
    "main/pak5.pk3": "ebc75ba147d28cf5397db9cf7647c2c5",
    "main/pak6enuk.pk3": "0dde61807fee408ca142c671e10baf33",
    "main/pak7.pk3": "622ad6039c8369738fc54b3573f6b739",
    "mainta/pak1.pk3": "f030b95c358eeed05891e0bbc9b8e361",
    "mainta/pak2.pk3": "16fceb0c8410ae87b0c6bae1ae761c5b",
    "mainta/pak3.pk3": "099d46871c7b7bbefbea0c72ccd6cea5",
    "mainta/pak4.pk3": "c4cd23103785916f723658159e9962b4",
    "mainta/pak5.pk3": "e07af969447d25d91c28f5dd00b84adc",
    "maintt/pak1.pk3": "f2ad44c4de4e7ef2b9411afe957e0527",
    "maintt/pak2.pk3": "46b5226a8d940f5ee7101dd75b7be48a",
    "maintt/pak3.pk3": "a3af0f4ba06a5d752105d0c237ee4db8",
    "maintt/pak4.pk3": "9ef5bfc0588ba782e41923f81f737fb4",
]

struct PakCheck: Equatable {
    var verified = 0
    var damaged = 0
    var missing = 0
    var other = 0  // pak files that are not retail ones

    var summary: String {
        if damaged == 0 && missing == 0 {
            return "\(verified) files OK"
        }
        return [damaged > 0 ? "\(damaged) damaged" : nil, missing > 0 ? "\(missing) missing" : nil]
            .compactMap { $0 }.joined(separator: ", ")
    }
}

/// Checks the retail pak files of each game folder that is installed, or
/// returns nil when none is.
func checkPaks(in folder: URL, md5: (URL) -> String?) -> PakCheck? {
    let files = FileManager.default
    let entries = (try? files.contentsOfDirectory(atPath: folder.path)) ?? []
    var check = PakCheck()
    var found = false
    for game in ["main", "mainta", "maintt"] {
        guard let entry = entries.first(where: { $0.lowercased() == game }) else { continue }
        found = true
        let gameFolder = folder.appendingPathComponent(entry)
        let paks = ((try? files.contentsOfDirectory(atPath: gameFolder.path)) ?? []).filter {
            $0.lowercased().hasPrefix("pak") && $0.lowercased().hasSuffix(".pk3")
        }
        for pak in paks {
            if let expected = retailPaks["\(game)/\(pak.lowercased())"] {
                if md5(gameFolder.appendingPathComponent(pak)) == expected {
                    check.verified += 1
                } else {
                    check.damaged += 1
                }
            } else {
                check.other += 1
            }
        }
        let present = Set(paks.map { "\(game)/\($0.lowercased())" })
        check.missing += retailPaks.keys.filter { $0.hasPrefix("\(game)/") && !present.contains($0) }.count
    }
    return found ? check : nil
}

// MARK: - Interface

#if canImport(SwiftUI)
import AppKit
import CryptoKit
import SwiftUI

/// Pure red. A 0K blue-light filter removes green and blue, so this is the
/// only accent that stays visible, and it stays darker than white text.
let accent = Color(red: 196 / 255, green: 0, blue: 0)

let folder = Bundle.main.bundleURL.deletingLastPathComponent()
let settingsFile = folder.appendingPathComponent("launcher.cfg")
let translocated = Bundle.main.bundlePath.contains("/AppTranslocation/")
let translocatedMessage =
    "macOS runs the launcher from a temporary copy, so it cannot find the game. In Terminal, from the game folder, run xattr -dr com.apple.quarantine . and open the launcher again."

/// Why the game folder cannot be used, if it cannot: the game keeps its
/// configs, saves and logs there, and the launcher its settings.
func folderProblem() -> String? {
    if translocated {
        return translocatedMessage
    }
    if !FileManager.default.isWritableFile(atPath: folder.path) {
        return "The game folder is read-only, so settings, game configs and saves cannot be kept. Move the game folder somewhere you can write to, such as your home folder."
    }
    return nil
}

/// Whether the user was told that settings cannot be saved.
var reportedSaveFailure = false

func saveSettings(_ config: Config) {
    // It holds server and RCON passwords, so it is written to a file that
    // only its owner can read, then moved over the old one.
    let temporaryFile = folder.appendingPathComponent(".launcher.cfg.tmp")
    do {
        try? FileManager.default.removeItem(at: temporaryFile)
        guard FileManager.default.createFile(
            atPath: temporaryFile.path, contents: nil, attributes: [.posixPermissions: 0o600]
        ) else {
            throw CocoaError(.fileWriteNoPermission)
        }
        let handle = try FileHandle(forWritingTo: temporaryFile)
        defer { try? handle.close() }
        try handle.write(contentsOf: Data(config.text.utf8))
        guard rename(temporaryFile.path, settingsFile.path) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
        }
    } catch {
        try? FileManager.default.removeItem(at: temporaryFile)
        NSLog("Could not save %@: %@", settingsFile.path, error.localizedDescription)
        if !reportedSaveFailure {
            reportedSaveFailure = true
            showAlert("The launcher settings could not be saved: \(error.localizedDescription)")
        }
    }
}

func showAlert(_ message: String) {
    let alert = NSAlert()
    alert.messageText = message
    alert.alertStyle = .warning
    alert.runModal()
}

func rgbColor(_ hex: String) -> Color {
    let rgb = Int(hex, radix: 16) ?? 0xFFFFFF
    return Color(
        red: Double(rgb >> 16 & 0xFF) / 255, green: Double(rgb >> 8 & 0xFF) / 255, blue: Double(rgb & 0xFF) / 255
    )
}

func md5(of file: URL) -> String? {
    guard let handle = try? FileHandle(forReadingFrom: file) else { return nil }
    defer { try? handle.close() }
    var hash = Insecure.MD5()
    do {
        while let data = try handle.read(upToCount: 1 << 20), !data.isEmpty {
            hash.update(data: data)
        }
    } catch {
        return nil
    }
    return hash.finalize().map { String(format: "%02x", $0) }.joined()
}

@main
struct LauncherApp: App {
    var body: some Scene {
        // A single window, which quits the launcher when it closes.
        Window("MoH Launcher", id: "launcher") {
            LauncherView()
        }
        .windowResizability(.contentSize)
    }
}

struct LauncherView: View {
    @State private var config = Config(text: (try? String(contentsOf: settingsFile, encoding: .utf8)) ?? "")
    @State private var namingShortcut: Int?
    @State private var shortcutName = ""
    @State private var pakCheck: PakCheck?
    @State private var checkingPaks = false
    @State private var checkedPaks = false

    var body: some View {
        VStack(spacing: 6) {
            gamePicker
            Card { serverRows }
            Card { botRows }
            Card { crosshairRows }
            HStack(spacing: 6) {
                LaunchButton(title: "Connect", icon: "play.fill") { launch(play: false) }
                    .help("Joins the server in Allied Assault.")
                LaunchButton(title: "Bots", icon: "person.2.fill") { launch(play: true) }
                    .help("Starts a bot match with cheats on, so dog and the other cheats work.")
            }
        }
        .padding(8)
        .frame(width: 520)
        .fixedSize()
        .preferredColorScheme(.dark)
        .tint(accent)
        .containerBackground(Color.black, for: .window)
        .onAppear {
            NSApp.appearance = NSAppearance(named: .darkAqua)
            if let problem = folderProblem() {
                // Settings would only fail to save after that.
                reportedSaveFailure = true
                DispatchQueue.main.async { showAlert(problem) }
            }
        }
        .onChange(of: config) { saveSettings(config) }
        .onChange(of: config.address) { config.addressChanged() }
        .onChange(of: config.game) { config.gameChanged() }
        .alert("Name this shortcut", isPresented: Binding(
            get: { namingShortcut != nil },
            set: { if !$0 { namingShortcut = nil } }
        )) {
            TextField("Name", text: $shortcutName)
            Button("Save") {
                if let index = namingShortcut {
                    config.saveShortcut(index, name: shortcutName)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var gamePicker: some View {
        HStack(spacing: 4) {
            ForEach(games.indices, id: \.self) { game in
                let selected = config.game == game
                Button { config.game = game } label: {
                    Image(nsImage: Self.icons[games[game].0] ?? NSImage())
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 22, height: 22)
                        .padding(3)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(selected ? accent : Color.clear, lineWidth: 1.5)
                        )
                        .opacity(selected ? 1 : 0.45)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(games[game].1)
            }
        }
    }

    private static let icons: [String: NSImage] = Dictionary(uniqueKeysWithValues: games.map { game in
        let image = Bundle.main.url(forResource: game.0, withExtension: "png").flatMap { NSImage(contentsOf: $0) } ?? NSImage()
        return (game.0, image)
    })

    // MARK: Cards

    @ViewBuilder private var serverRows: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 6) {
            GridRow {
                TextField("Nickname", text: $config.name).textFieldStyle(.roundedBorder)
                shortcutRow(0)
            }
            GridRow {
                TextField("IP", text: $config.address).textFieldStyle(.roundedBorder)
                shortcutRow(1)
            }
            GridRow {
                BulletField("Password", text: $config.password)
                shortcutRow(2)
            }
            GridRow {
                BulletField("RCON", text: $config.rcon)
                shortcutRow(3)
            }
        }
    }

    private func shortcutRow(_ index: Int) -> some View {
        let shortcut = config.shortcuts[index]
        let empty = shortcut.name.isEmpty
        let loaded = !empty
            && shortcut.address == config.trimmedAddress
            && shortcut.password == config.password
            && shortcut.rcon == config.rcon
        return HStack(spacing: 4) {
            Button { config.applyShortcut(index) } label: {
                Text(empty ? "Empty" : shortcut.name)
                    .lineLimit(1)
                    .foregroundStyle(empty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(empty)
            .help(shortcut.address)
            if index != 0 {
                Button {
                    shortcutName = empty ? config.trimmedAddress : shortcut.name
                    namingShortcut = index
                } label: {
                    Image(systemName: loaded ? "bookmark.fill" : "bookmark")
                        .foregroundStyle(loaded ? accent : .primary)
                }
                .disabled(config.trimmedAddress.isEmpty)
                .help("Save the server and passwords above in this shortcut")
                Button { config.shortcuts[index] = Shortcut() } label: {
                    Image(systemName: "trash")
                }
                .disabled(empty)
                .help("Clear this shortcut")
            }
            Button {
                config.applyShortcut(index)
                launch(play: false)
            } label: {
                Image(systemName: "play.fill")
            }
            .disabled(empty)
            .help("Connect to \(shortcut.name)")
        }
        .controlSize(.small)
        .padding(.horizontal, 4)
        .padding(.vertical, 1)
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(loaded ? accent : Color.clear, lineWidth: 1.5)
        )
    }

    @ViewBuilder private var botRows: some View {
        HStack(spacing: 6) {
            Picker("", selection: $config.gametype) {
                Text("FFA").tag(1)
                Text("TDM").tag(2)
                Text("OBJ").tag(4)
            }
            .labelsHidden()
            .fixedSize()
            .help("Free-for-all, team deathmatch, or objective")
            Picker("", selection: $config.map) {
                ForEach(maps(for: config.game), id: \.self) { path in
                    Text(mapName(path)).tag(path)
                }
            }
            .labelsHidden()
            UnitField(value: $config.bots, range: 1...maxBots, step: 1, unit: "Bots")
                .help("How many bots join the match")
            Picker("", selection: $config.botTeam) {
                Text("Auto").tag("auto")
                Text("Allies").tag("allies")
                Text("Axis").tag("axis")
            }
            .labelsHidden()
            .fixedSize()
            .help("The team the bots join")
        }
        HStack(spacing: 6) {
            UnitField(value: $config.health, range: 1...1000, step: 25, unit: "HP")
                .help("Player health")
            Picker("", selection: $config.runSpeed) {
                ForEach(Config.runSpeeds, id: \.self) { Text(Config.runSpeedLabel($0)).tag($0) }
            }
            .labelsHidden()
            .fixedSize()
            .help("250 is Allied Assault. 287 is Spearhead and Breakthrough.")
            Toggle("Infinite ammo", isOn: $config.infiniteAmmo)
                .help("Clips never empty, so weapons never need reloading.")
            Toggle("SH/BT animations", isOn: $config.painAnims)
                .disabled(config.game == 0)
                .help("Play the Spearhead and Breakthrough pain animations when players are hit.")
        }
    }

    @ViewBuilder private var crosshairRows: some View {
        HStack(spacing: 6) {
            CrosshairPreview(config: config)
                .frame(width: 44, height: 22)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.black.opacity(0.85)))
            UnitField(value: $config.crosshairLength, range: Config.crosshairLengths, step: 1, unit: "Length")
            UnitField(value: $config.crosshairGap, range: Config.crosshairGaps, step: 1, unit: "Gap")
            UnitField(value: $config.crosshairThickness, range: Config.crosshairThicknesses, step: 1, unit: "Thick")
            Picker("", selection: $config.crosshairColor) {
                ForEach(Config.crosshairColors, id: \.hex) { color in
                    Text(color.name).tag(color.hex)
                }
            }
            .labelsHidden()
            .fixedSize()
            Button("Reset") {
                config.crosshairLength = Config.crosshairDefaults.length
                config.crosshairGap = Config.crosshairDefaults.gap
                config.crosshairThickness = Config.crosshairDefaults.thickness
                config.crosshairColor = Config.crosshairDefaults.color
            }
            .fixedSize()
        }
        .help("Crosshair sizes are in pixels at 1080p and scale with the resolution.")
        HStack(spacing: 8) {
            Picker("", selection: $config.resolution) {
                ForEach(resolutions, id: \.self) { Text($0).tag($0) }
            }
            .labelsHidden()
            .fixedSize()
            Toggle("Fullscreen", isOn: $config.fullscreen)
            Spacer(minLength: 0)
            verifyButton
        }
    }

    /// Checks the retail pak files: a grey check until used, a white check
    /// when all are intact, or a red mark when any are missing or damaged.
    /// Green would disappear under a filter that removes every color but red.
    private var verifyButton: some View {
        Button(action: verifyPaks) {
            Group {
                if checkingPaks {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: pakFailed ? "xmark" : "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(pakColor)
                }
            }
            .frame(width: 26, height: 26)
            .background(Circle().fill(Color.primary.opacity(0.06)))
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(checkingPaks)
        .help(pakHelp)
    }

    /// True after a check that found missing files, damaged files, or no game.
    private var pakFailed: Bool {
        guard checkedPaks else { return false }
        guard let check = pakCheck else { return true }
        return check.damaged > 0 || check.missing > 0
    }

    private var pakColor: Color {
        guard let check = pakCheck else { return .secondary }
        return check.damaged > 0 || check.missing > 0 ? accent : .white
    }

    private var pakHelp: String {
        if checkingPaks {
            return "Verifying game files…"
        }
        guard checkedPaks else {
            return "Verify the retail game files of Allied Assault, Spearhead and Breakthrough"
        }
        guard let check = pakCheck else {
            return "No game folders found"
        }
        return "\(check.summary): \(check.verified) retail pak files verified, \(check.other) other pak files"
    }

    private func verifyPaks() {
        checkingPaks = true
        DispatchQueue.global(qos: .userInitiated).async {
            let check = checkPaks(in: folder, md5: md5(of:))
            DispatchQueue.main.async {
                pakCheck = check
                checkingPaks = false
                checkedPaks = true
            }
        }
    }

    // MARK: Launch

    private func launch(play: Bool) {
        // Commit a field still being edited, then read the settings.
        _ = NSApp.keyWindow?.makeFirstResponder(nil)
        DispatchQueue.main.async {
            let fields = play
                ? [("nickname", config.name)]
                : [("nickname", config.name), ("server address", config.address),
                   ("password", config.password), ("RCON password", config.rcon)]
            let appName = play ? "mohbots" : "openmohaa"
            let app = folder.appendingPathComponent("\(appName).app")
            guard FileManager.default.fileExists(atPath: app.path) else {
                return showAlert(
                    translocated
                        ? translocatedMessage
                        : "\(appName).app was not found. Put launcher.app in the game folder, next to \(appName).app."
                )
            }
            if let field = fields.first(where: { !isSafe($0.1) }) {
                return showAlert("The \(field.0) cannot contain line breaks or any of + ; \" // /* \\")
            }
            if !play {
                config.rememberPasswords()
            }
            saveSettings(config)

            // Open the app the way a double-click does. macOS reads the
            // program name from the app and shows the normal download check.
            // Play starts a new copy: an already running game would come
            // forward and ignore the map and the bot count. sv_maxbots is
            // latched, so those have to be on the command line of that copy.
            let open = NSWorkspace.OpenConfiguration()
            open.arguments = play ? config.playArgs() : config.connectArgs()
            open.createsNewApplicationInstance = play
            NSWorkspace.shared.openApplication(at: app, configuration: open) { _, error in
                DispatchQueue.main.async {
                    if let error {
                        showAlert("The game could not be started: \(error.localizedDescription)")
                    } else {
                        NSApp.terminate(nil)
                    }
                }
            }
        }
    }
}

// MARK: - Controls

/// A group of rows in a subtly filled, rounded box.
struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) { content }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.045)))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }
}

/// A number box that reads as "4 Bots" or "250 HP", with the same inset and
/// arrow size as the menus beside it.
struct UnitField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String

    var body: some View {
        HStack(spacing: 4) {
            TightNumber(value: $value, range: range)
            Text(unit).foregroundStyle(.secondary)
            Spacer(minLength: 6)
            VStack(spacing: 0) {
                stepButton("chevron.up") { value = min(value + step, range.upperBound) }
                stepButton("chevron.down") { value = max(value - step, range.lowerBound) }
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 6)
        .frame(height: 22)
        .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color.primary.opacity(0.08)))
        .fixedSize()
    }

    private func stepButton(_ name: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 7, weight: .semibold))
                .frame(width: 12, height: 8)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
}

/// A borderless number that sits on the same line as the menus' titles.
private struct TightNumber: NSViewRepresentable {
    @Binding var value: Int
    let range: ClosedRange<Int>

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: String(value))
        field.isBezeled = false
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        field.alignment = .left
        field.maximumNumberOfLines = 1
        field.delegate = context.coordinator
        field.setContentHuggingPriority(.required, for: .horizontal)
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.range = range
        context.coordinator.binding = $value
        if field.currentEditor() == nil, field.stringValue != String(value) {
            field.stringValue = String(value)
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: NSTextField, context: Context) -> CGSize? {
        let sample = String(repeating: "0", count: max(1, String(range.upperBound).count))
        let width = (sample as NSString).size(withAttributes: [.font: nsView.font as Any]).width
        return CGSize(width: width + 2, height: 16)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value, range: range)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var binding: Binding<Int>
        var range: ClosedRange<Int>

        init(value: Binding<Int>, range: ClosedRange<Int>) {
            binding = value
            self.range = range
        }

        func controlTextDidEndEditing(_ note: Notification) {
            guard let field = note.object as? NSTextField else { return }
            let number = Int(field.stringValue) ?? binding.wrappedValue
            let clamped = min(max(number, range.lowerBound), range.upperBound)
            binding.wrappedValue = clamped
            field.stringValue = String(clamped)
        }
    }
}

/// A password box that shows dots but is not a secure field, so macOS and
/// password apps do not offer to fill it.
struct BulletField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String

    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        _text = text
    }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField()
        field.placeholderString = placeholder
        field.isBezeled = true
        field.bezelStyle = .roundedBezel
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        field.isAutomaticTextCompletionEnabled = false
        field.delegate = context.coordinator
        field.stringValue = String(repeating: "•", count: (text as NSString).length)
        context.coordinator.real = text
        return field
    }

    func updateNSView(_ field: NSTextField, context: Context) {
        context.coordinator.binding = $text
        guard context.coordinator.real != text else { return }
        context.coordinator.real = text
        let masked = String(repeating: "•", count: (text as NSString).length)
        if let editor = field.currentEditor() as? NSTextView {
            editor.string = masked
            editor.setSelectedRange(NSRange(location: masked.count, length: 0))
        } else {
            field.stringValue = masked
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        var binding: Binding<String>
        var real: String

        init(text: Binding<String>) {
            binding = text
            real = text.wrappedValue
        }

        func control(_ control: NSControl, textView: NSTextView, shouldChangeTextIn range: NSRange, replacementString: String?) -> Bool {
            let insert = replacementString ?? ""
            let current = real as NSString
            let start = min(max(range.location, 0), current.length)
            let length = min(max(range.length, 0), current.length - start)
            let next = NSMutableString(string: current)
            next.replaceCharacters(in: NSRange(location: start, length: length), with: insert)
            real = next as String
            binding.wrappedValue = real
            let masked = String(repeating: "•", count: (real as NSString).length)
            textView.string = masked
            textView.setSelectedRange(NSRange(location: min(start + (insert as NSString).length, (masked as NSString).length), length: 0))
            return false
        }
    }
}

/// The crosshair as the game draws it at the chosen resolution: sizes scale
/// with the screen height and round to whole pixels, and the gap grows so
/// thick arms do not touch.
struct CrosshairPreview: View {
    let config: Config

    var body: some View {
        Canvas { context, size in
            let height = Double(pixelSize(config.resolution).height)
            let scale = height / 1080
            let pixels = { (value: Int) in max(1, (Double(value) * scale).rounded()) }
            let length = pixels(config.crosshairLength)
            let thickness = pixels(config.crosshairThickness)
            let gap = max(pixels(config.crosshairGap), thickness / 2 + 0.5)
            let x = size.width / 2
            let y = size.height / 2
            let arms = [
                CGRect(x: x - gap - length, y: y - thickness / 2, width: length, height: thickness),
                CGRect(x: x + gap, y: y - thickness / 2, width: length, height: thickness),
                CGRect(x: x - thickness / 2, y: y - gap - length, width: thickness, height: length),
                CGRect(x: x - thickness / 2, y: y + gap, width: thickness, height: length),
            ]
            for arm in arms {
                context.fill(Path(arm), with: .color(rgbColor(config.crosshairColor)))
            }
        }
        .accessibilityLabel("Crosshair preview")
    }
}

/// The full-width accent button that starts the game.
struct LaunchButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 12, weight: .semibold))
                Text(title).font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(accent))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
#endif
