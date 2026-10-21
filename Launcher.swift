// launcher.app: joins a server or starts a local bot match.
//
// It sits in the game folder next to the openmohaa binary and keeps its
// settings in launcher.cfg beside it. bundle.sh builds it.

import Foundation

// MARK: - Settings

/// Maps offered for bot matches. Spearhead also loads the Allied Assault
/// maps, and Breakthrough loads both, so each list starts with its own.
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

func maps(for game: Int) -> [String] {
    switch game {
    case 0: return aaMaps
    case 1: return shMaps + aaMaps
    default: return btMaps + shMaps + aaMaps
    }
}

let resolutions = [
    "800x600", "960x720", "1024x768", "1152x864", "1280x720", "1280x960",
    "1280x1024", "1344x1008", "1600x1200", "1920x1080",
]

/// The previous launcher saved the resolution as an index into this list.
let oldResolutions = [
    "800x600", "960x720", "1024x768", "1152x864", "1280x720", "1280x1024",
    "1600x1200", "1920x1080", "1280x960", "1344x1008",
]

let botTeams = ["auto", "allies", "axis"]  // g_bot_team values
let maxBots = 62  // 64 clients minus the two player slots of a bot match
let shortcutCount = 3

/// com_target_game values 0, 1 and 2.
let games = [("AA", "Allied Assault"), ("SH", "Spearhead"), ("BT", "Breakthrough")]

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
    var shortcuts = Array(repeating: Shortcut(), count: shortcutCount)
    var gametype = 1  // 1 free-for-all, 2 team match
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

    static func runSpeed(for game: Int) -> Int {
        game == 0 ? 250 : 287
    }

    /// Allied Assault servers turn an sv_runspeed of 287 back into 250 while
    /// sprint is off, so it stops one short of that.
    static func runSpeeds(for game: Int) -> ClosedRange<Int> {
        game == 0 ? 250...286 : 250...287
    }

    /// A six-digit RGB value, or white.
    static func color(_ value: String) -> String {
        let hex = value.hasPrefix("#") ? String(value.dropFirst()) : value
        return hex.count == 6 && hex.allSatisfy(\.isHexDigit) ? hex.uppercased() : crosshairDefaults.color
    }

    var trimmedAddress: String {
        address.trimmingCharacters(in: .whitespaces)
    }

    /// The shortcut saved for the typed address, if any.
    var shortcutIndex: Int? {
        let address = trimmedAddress
        return address.isEmpty ? nil : shortcuts.firstIndex { !$0.name.isEmpty && $0.address == address }
    }

    /// Passwords belong to one server, so another address gets its own or none.
    mutating func addressChanged() {
        let shortcut = shortcutIndex.map { shortcuts[$0] } ?? Shortcut()
        password = shortcut.password
        rcon = shortcut.rcon
    }

    /// A run speed left at the old game's default follows the new game, and
    /// a map the new game cannot load gives way to its first map.
    mutating func gameChanged() {
        if runSpeed == Config.runSpeed(for: 0) || runSpeed == Config.runSpeed(for: 1) {
            runSpeed = Config.runSpeed(for: game)
        }
        runSpeed = min(runSpeed, Config.runSpeeds(for: game).upperBound)
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
        let name = name.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty {
            for other in shortcuts.indices where other != index && shortcuts[other].address == trimmedAddress {
                shortcuts[other] = Shortcut()
            }
            shortcuts[index] = Shortcut(name: name, address: trimmedAddress, password: password, rcon: rcon)
        }
    }

    /// Keeps passwords edited before connecting in the shortcut of that server.
    mutating func rememberPasswords() {
        if let index = shortcutIndex {
            shortcuts[index].password = password
            shortcuts[index].rcon = rcon
        }
    }

    // MARK: Launch arguments

    /// Arguments shared by Connect and Play. The engine keeps configs and
    /// other user data in the game folder by itself.
    func commonArgs() -> [String] {
        let size = resolution.split(separator: "x").map(String.init)
        var args: [String] = []
        if !name.isEmpty {
            args += set("name", name)
        }
        args += set("cl_playintro", 0)
        args += set("r_fullscreen", fullscreen)
        args += set("r_mode", -1) + set("r_customwidth", size[0]) + set("r_customheight", size[1])
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
        for index in shortcuts.indices {
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
        gametype = choice("bot_game_type", 1...2, gametype)
        map = values["bot_map"].flatMap { maps(for: game).contains($0) ? $0 : nil } ?? maps(for: game)[0]
        bots = number("bot_count", 1...maxBots, bots)
        botTeam = values["bot_team"].flatMap { botTeams.contains($0) ? $0 : nil } ?? botTeam
        health = number("player_health", 1...1000, health)
        runSpeed = number("run_speed", Config.runSpeeds(for: game), Config.runSpeed(for: game))
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

    init() {}

    var text: String {
        var lines = [
            "game=\(game)", "nickname=\(name)", "ip=\(address)", "password=\(password)", "rcon=\(rcon)",
            "bot_game_type=\(gametype)", "bot_map=\(map)", "bot_count=\(bots)", "bot_team=\(botTeam)",
            "player_health=\(health)", "run_speed=\(runSpeed)", "infinite_ammo=\(infiniteAmmo ? 1 : 0)",
            "pain_anims=\(painAnims ? 1 : 0)",
            "fullscreen_enabled=\(fullscreen ? 1 : 0)", "resolution=\(resolution)",
            "crosshair_length=\(crosshairLength)", "crosshair_gap=\(crosshairGap)",
            "crosshair_thickness=\(crosshairThickness)", "crosshair_color=\(crosshairColor)",
        ]
        for (index, shortcut) in shortcuts.enumerated() where !shortcut.name.isEmpty {
            lines += [
                "bookmark_name_\(index)=\(shortcut.name)", "bookmark_ip_\(index)=\(shortcut.address)",
                "bookmark_pass_\(index)=\(shortcut.password)", "bookmark_rcon_\(index)=\(shortcut.rcon)",
            ]
        }
        return lines.joined(separator: "\n") + "\n"
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

let accent = Color(red: 123 / 255, green: 79 / 255, blue: 191 / 255)
let labelWidth: CGFloat = 76

let folder = Bundle.main.bundleURL.deletingLastPathComponent()
let settingsFile = folder.appendingPathComponent("launcher.cfg")
let translocated = Bundle.main.bundlePath.contains("/AppTranslocation/")
let translocatedMessage =
    "macOS runs the launcher from a temporary copy, so it cannot find the game. Open install.command in the game folder, then open the launcher again."

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
        Window("OpenMoHAA", id: "launcher") {
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
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Text("Nickname").foregroundStyle(.secondary)
                TextField("", text: $config.name)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                Spacer()
                verifyButton
                Toggle("Fullscreen", isOn: $config.fullscreen)
                    .padding(.horizontal, 8)
                Picker("Resolution", selection: $config.resolution) {
                    ForEach(resolutions, id: \.self) { Text($0).tag($0) }
                }
                .fixedSize()
            }
            // fixedSize stretches both cards to the taller one.
            HStack(alignment: .top, spacing: 12) {
                Card { serverRows }
                Card { botRows }
            }
            .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 12) {
                LaunchButton(title: "Connect", icon: "bolt.fill") { launch(play: false) }
                    .help("Joins the server in Allied Assault.")
                LaunchButton(title: "Play", icon: "play.fill") { launch(play: true) }
                    .help("Starts a bot match with cheats on, so dog and the other cheats work.")
            }
            Card { crosshairRows }
        }
        .padding(14)
        .frame(width: 760)
        .fixedSize()
        .onAppear {
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
        HStack(spacing: 0) {
            ForEach(games.indices, id: \.self) { game in
                let selected = config.game == game
                Button { config.game = game } label: {
                    Text(games[game].0)
                        .font(.system(size: 12, weight: selected ? .semibold : .regular))
                        .frame(width: 56)
                        .padding(.vertical, 4)
                        .foregroundStyle(selected ? Color.white : Color.secondary)
                        .background(selected ? accent : Color.clear)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(games[game].1)
            }
        }
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    // MARK: Cards

    @ViewBuilder private var serverRows: some View {
        Row("Server") {
            TextField("address:port", text: $config.address).textFieldStyle(.roundedBorder)
        }
        Row("Password") {
            SecureField("", text: $config.password).textFieldStyle(.roundedBorder)
        }
        Row("RCON") {
            SecureField("", text: $config.rcon).textFieldStyle(.roundedBorder)
        }
        Divider()
        ForEach(0..<shortcutCount, id: \.self) { index in
            shortcutRow(index)
        }
    }

    private func shortcutRow(_ index: Int) -> some View {
        let shortcut = config.shortcuts[index]
        let empty = shortcut.name.isEmpty
        return Row(index == 0 ? "Shortcuts" : "") {
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
            Button {
                config.applyShortcut(index)
                launch(play: false)
            } label: {
                Image(systemName: "play.fill")
            }
            .disabled(empty)
            .help("Connect to \(shortcut.name)")
            Button("Save") {
                shortcutName = empty ? config.trimmedAddress : shortcut.name
                namingShortcut = index
            }
            .disabled(config.trimmedAddress.isEmpty)
            .help("Save the server and passwords above in this shortcut")
            Button { config.shortcuts[index] = Shortcut() } label: {
                Image(systemName: "trash")
            }
            .disabled(empty)
            .help("Clear this shortcut")
        }
        .controlSize(.small)
    }

    @ViewBuilder private var botRows: some View {
        Row("Game") {
            gamePicker
        }
        Row("Map") {
            Picker("", selection: $config.gametype) {
                Text("FFA").tag(1)
                Text("TDM").tag(2)
            }
            .labelsHidden()
            .fixedSize()
            .help("Free-for-all or team deathmatch")
            Picker("", selection: $config.map) {
                ForEach(maps(for: config.game), id: \.self) { Text($0).tag($0) }
            }
            .labelsHidden()
        }
        Row("Bots") {
            NumberField(value: $config.bots, range: 1...maxBots, step: 1)
            Spacer()
            Text("Team").foregroundStyle(.secondary)
            Picker("", selection: $config.botTeam) {
                Text("Auto").tag("auto")
                Text("Allies").tag("allies")
                Text("Axis").tag("axis")
            }
            .labelsHidden()
            .fixedSize()
            .help("The team the bots join")
        }
        Row("Health") {
            NumberField(value: $config.health, range: 1...1000, step: 25)
        }
        Row("Run speed") {
            IntSlider(value: $config.runSpeed, range: Config.runSpeeds(for: config.game))
        }
        .help("Allied Assault: 250, Spearhead and Breakthrough: 287")
        Row("") {
            Toggle("Infinite ammo", isOn: $config.infiniteAmmo)
                .help("Clips never empty, so weapons never need reloading.")
            Toggle("SH/BT pain", isOn: $config.painAnims)
                .disabled(config.game == 0)
                .help("Play the Spearhead and Breakthrough pain animations when players are hit.")
        }
    }

    @ViewBuilder private var crosshairRows: some View {
        HStack(alignment: .center, spacing: 8) {
            CrosshairPreview(config: config)
                .frame(width: labelWidth, height: 60)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.black.opacity(0.85)))
            Grid(horizontalSpacing: 24, verticalSpacing: 8) {
                GridRow {
                    LabeledSlider("Length", value: $config.crosshairLength, range: Config.crosshairLengths)
                    LabeledSlider("Gap", value: $config.crosshairGap, range: Config.crosshairGaps)
                }
                GridRow {
                    LabeledSlider("Thickness", value: $config.crosshairThickness, range: Config.crosshairThicknesses)
                    HStack(spacing: 8) {
                        Text("Color").foregroundStyle(.secondary).frame(width: 64, alignment: .leading)
                        ColorPicker("", selection: crosshairColor, supportsOpacity: false)
                            .labelsHidden()
                        Spacer()
                        Button("Reset") {
                            config.crosshairLength = Config.crosshairDefaults.length
                            config.crosshairGap = Config.crosshairDefaults.gap
                            config.crosshairThickness = Config.crosshairDefaults.thickness
                            config.crosshairColor = Config.crosshairDefaults.color
                        }
                    }
                }
            }
        }
        .help("Crosshair sizes are in pixels at 1080p and scale with the resolution.")
    }

    private var crosshairColor: Binding<Color> {
        Binding(
            get: { rgbColor(config.crosshairColor) },
            set: { color in
                guard let rgb = NSColor(color).usingColorSpace(.sRGB) else { return }
                let byte = { (value: CGFloat) in min(max(Int((value * 255).rounded()), 0), 255) }
                config.crosshairColor = String(
                    format: "%02X%02X%02X", byte(rgb.redComponent), byte(rgb.greenComponent), byte(rgb.blueComponent)
                )
            }
        )
    }

    /// Checks the retail pak files: a grey check until used, a spinner while
    /// checking, then a green check when all are intact or a red cross when
    /// any is damaged. The tooltip gives the details.
    private var verifyButton: some View {
        Button(action: verifyPaks) {
            Group {
                if checkingPaks {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: (pakCheck?.damaged ?? 0) > 0 ? "xmark" : "checkmark")
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

    private var pakColor: Color {
        guard let check = pakCheck else { return .secondary }
        return check.damaged > 0 ? .red : check.missing > 0 ? .orange : .green
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
            let game = folder.appendingPathComponent("openmohaa")
            guard FileManager.default.fileExists(atPath: game.path) else {
                return showAlert(
                    translocated
                        ? translocatedMessage
                        : "openmohaa was not found. Put launcher.app in the game folder, next to openmohaa."
                )
            }
            guard FileManager.default.isExecutableFile(atPath: game.path) else {
                return showAlert("openmohaa cannot be run. In Terminal, run chmod +x on the openmohaa file in the game folder.")
            }
            if let field = fields.first(where: { !isSafe($0.1) }) {
                return showAlert("The \(field.0) cannot contain line breaks or any of + ; \" // /* \\")
            }
            if !play {
                config.rememberPasswords()
            }
            saveSettings(config)

            let process = Process()
            process.executableURL = game
            process.arguments = play ? config.playArgs() : config.connectArgs()
            process.currentDirectoryURL = folder
            do {
                try process.run()
                NSApp.terminate(nil)
            } catch {
                showAlert("The game could not be started: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Controls

/// A group of rows in a subtly filled, rounded box.
struct Card<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) { content }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.045)))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        )
    }
}

/// A right-aligned label followed by its controls, so labels line up in
/// every card.
struct Row<Content: View>: View {
    let label: String
    let content: Content

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label).foregroundStyle(.secondary).frame(width: labelWidth, alignment: .trailing)
            content
        }
    }
}

/// A number box with a stepper that keeps whole numbers in range.
struct NumberField: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int

    var body: some View {
        HStack(spacing: 2) {
            TextField(
                "",
                value: Binding(get: { value }, set: { value = min(max($0, range.lowerBound), range.upperBound) }),
                format: .number.grouping(.never)
            )
            .textFieldStyle(.roundedBorder)
            .frame(width: 54)
            Stepper("", value: $value, in: range, step: step).labelsHidden()
        }
    }
}

/// A slider over whole numbers with its value beside it.
struct IntSlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        Slider(
            value: Binding(get: { Double(value) }, set: { value = Int($0.rounded()) }),
            in: Double(range.lowerBound)...Double(range.upperBound)
        )
        Text("\(value)").monospacedDigit().frame(width: 30, alignment: .trailing)
    }
}

/// An IntSlider with a short label in front, for rows narrower than a Row.
struct LabeledSlider: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    init(_ label: String, value: Binding<Int>, range: ClosedRange<Int>) {
        self.label = label
        self._value = value
        self.range = range
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(label).foregroundStyle(.secondary).frame(width: 64, alignment: .leading)
            IntSlider(value: $value, range: range)
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
            let height = Double(config.resolution.split(separator: "x").last ?? "") ?? 1080
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
            .padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(accent))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
#endif
