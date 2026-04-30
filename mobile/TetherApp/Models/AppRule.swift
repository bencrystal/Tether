import Foundation
#if canImport(FamilyControls)
import FamilyControls
#endif

struct AppRule: Codable, Identifiable {
    let id: UUID
    var displayName: String
    var warnMinutes: Int
    var zapMinutes: Int

    // FamilyControls ApplicationToken is not directly Codable,
    // so we store its Data representation
    var appTokenData: Data?

    init(displayName: String, warnMinutes: Int = 10, zapMinutes: Int = 15, appTokenData: Data? = nil) {
        self.id = UUID()
        self.displayName = displayName
        self.warnMinutes = warnMinutes
        self.zapMinutes = zapMinutes
        self.appTokenData = appTokenData
    }
}

// MARK: - Persistence via App Group UserDefaults

class RuleStore: ObservableObject {
    @Published var rules: [AppRule] = []

    private let defaults: UserDefaults

    init() {
        self.defaults = UserDefaults(suiteName: appGroupID) ?? .standard
        load()
    }

    func load() {
        guard let data = defaults.data(forKey: SharedKeys.rules),
              let decoded = try? JSONDecoder().decode([AppRule].self, from: data) else {
            rules = []
            return
        }
        rules = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        defaults.set(data, forKey: SharedKeys.rules)
    }

    func add(_ rule: AppRule) {
        rules.append(rule)
        save()
    }

    func update(_ rule: AppRule) {
        guard let idx = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[idx] = rule
        save()
    }

    func delete(_ rule: AppRule) {
        rules.removeAll { $0.id == rule.id }
        save()
    }
}
