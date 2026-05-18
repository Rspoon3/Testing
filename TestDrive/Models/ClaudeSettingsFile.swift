//
//  ClaudeSettingsFile.swift
//  TestDrive
//

import Foundation

/// Whether the underlying file is the committed `settings.json` or the gitignored `settings.local.json`.
enum ClaudeSettingsScope: String, Sendable {
    case shared
    case local

    var fileName: String {
        switch self {
        case .shared: "settings.json"
        case .local: "settings.local.json"
        }
    }
}

/// A parsed view of one `.claude/settings*.json` file. The raw JSON tree is kept so writes
/// preserve unknown keys (`permissions`, `env`, `hooks`, etc.) untouched.
struct ClaudeSettingsFile: Hashable, Sendable {
    let url: URL
    let scope: ClaudeSettingsScope
    private(set) var root: JSONValue

    // MARK: - Initializer

    init(url: URL, scope: ClaudeSettingsScope, root: JSONValue = .object([:])) {
        self.url = url
        self.scope = scope
        self.root = root
    }

    // MARK: - Plugin accessors

    /// `enabledPlugins` mapped to `[pluginIdentifier: isEnabled]`.
    var enabledPlugins: [String: Bool] {
        guard case .object(let plugins) = root.asObject["enabledPlugins"] ?? .null else { return [:] }
        return plugins.compactMapValues { $0.asBool }
    }

    /// `enabledMcpjsonServers` array values.
    var enabledMcpServers: [String] {
        root.asObject["enabledMcpjsonServers"]?.asArray.compactMap(\.asString) ?? []
    }

    /// `disabledMcpjsonServers` array values.
    var disabledMcpServers: [String] {
        root.asObject["disabledMcpjsonServers"]?.asArray.compactMap(\.asString) ?? []
    }

    /// `enableAllProjectMcpServers` flag.
    var enableAllProjectMcpServers: Bool {
        root.asObject["enableAllProjectMcpServers"]?.asBool ?? false
    }

    // MARK: - Mutations

    /// Sets the enabled state of a plugin. Pass `nil` to remove the entry entirely.
    mutating func setPlugin(_ identifier: String, enabled: Bool?) {
        var object = root.asObject
        var plugins = object["enabledPlugins"]?.asObject ?? [:]
        if let enabled {
            plugins[identifier] = .bool(enabled)
        } else {
            plugins.removeValue(forKey: identifier)
        }
        if plugins.isEmpty {
            object.removeValue(forKey: "enabledPlugins")
        } else {
            object["enabledPlugins"] = .object(plugins)
        }
        root = .object(object)
    }

    /// Adds or removes an MCP server from `enabledMcpjsonServers`.
    mutating func setMcpServerEnabled(_ name: String, enabled: Bool) {
        var object = root.asObject
        var enabledList = (object["enabledMcpjsonServers"]?.asArray.compactMap(\.asString)) ?? []
        var disabledList = (object["disabledMcpjsonServers"]?.asArray.compactMap(\.asString)) ?? []

        enabledList.removeAll { $0 == name }
        disabledList.removeAll { $0 == name }
        if enabled {
            enabledList.append(name)
        } else {
            disabledList.append(name)
        }

        if enabledList.isEmpty {
            object.removeValue(forKey: "enabledMcpjsonServers")
        } else {
            object["enabledMcpjsonServers"] = .array(enabledList.map { .string($0) })
        }
        if disabledList.isEmpty {
            object.removeValue(forKey: "disabledMcpjsonServers")
        } else {
            object["disabledMcpjsonServers"] = .array(disabledList.map { .string($0) })
        }
        root = .object(object)
    }

    /// Reverts a server back to its inherited default by removing it from both lists.
    mutating func clearMcpServerOverride(_ name: String) {
        var object = root.asObject
        if var enabledList = object["enabledMcpjsonServers"]?.asArray {
            enabledList.removeAll { $0.asString == name }
            if enabledList.isEmpty {
                object.removeValue(forKey: "enabledMcpjsonServers")
            } else {
                object["enabledMcpjsonServers"] = .array(enabledList)
            }
        }
        if var disabledList = object["disabledMcpjsonServers"]?.asArray {
            disabledList.removeAll { $0.asString == name }
            if disabledList.isEmpty {
                object.removeValue(forKey: "disabledMcpjsonServers")
            } else {
                object["disabledMcpjsonServers"] = .array(disabledList)
            }
        }
        root = .object(object)
    }
}
