import SwiftUI

struct HomeView: View {
    @EnvironmentObject var bleManager: BLEManager
    @EnvironmentObject var ruleStore: RuleStore
    @State private var showingAppPicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // BLE status bar
                HStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(bleManager.connectionState.rawValue)
                        .font(.subheadline)
                    if let name = bleManager.deviceName,
                       bleManager.connectionState == .connected {
                        Text("— \(name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))

                // Rules list
                if ruleStore.rules.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No apps monitored yet")
                            .font(.headline)
                        Text("Tap + to add an app and set time limits")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(ruleStore.rules) { rule in
                            NavigationLink(destination: RuleEditView(rule: rule)) {
                                RuleRow(rule: rule)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                ruleStore.delete(ruleStore.rules[index])
                            }
                        }
                    }
                }

                // Debug buttons (visible during prototype)
                #if DEBUG
                debugButtons
                #endif
            }
            .navigationTitle("Tether")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAppPicker = true }) {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if bleManager.connectionState == .disconnected {
                        Button("Scan") { bleManager.scan() }
                    }
                }
            }
            .sheet(isPresented: $showingAppPicker) {
                AppPickerView()
            }
        }
    }

    private var statusColor: Color {
        switch bleManager.connectionState {
        case .connected:    return .green
        case .connecting:   return .orange
        case .scanning:     return .orange
        case .disconnected: return .red
        }
    }

    #if DEBUG
    private var debugButtons: some View {
        HStack(spacing: 16) {
            Button("Warn") { bleManager.sendCommand(.warn) }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            Button("Zap") { bleManager.sendCommand(.zap) }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            Button("Off") { bleManager.sendCommand(.off) }
                .buttonStyle(.bordered)
        }
        .padding()
    }
    #endif
}

struct RuleRow: View {
    let rule: AppRule

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rule.displayName)
                    .font(.headline)
                HStack(spacing: 12) {
                    Label("\(rule.warnMinutes)m", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Label("\(rule.zapMinutes)m", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
