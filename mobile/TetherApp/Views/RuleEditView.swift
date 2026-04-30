import SwiftUI

struct RuleEditView: View {
    @EnvironmentObject var ruleStore: RuleStore
    @Environment(\.dismiss) private var dismiss

    @State var rule: AppRule

    var body: some View {
        Form {
            Section(header: Text("App")) {
                Text(rule.displayName)
                    .font(.headline)
            }

            Section(header: Text("Warning Threshold")) {
                HStack {
                    Text("\(rule.warnMinutes) min")
                        .frame(width: 60, alignment: .leading)
                    Slider(value: warnBinding, in: 1...60, step: 1)
                }
                Text("LED slow-blinks 3 times")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Zap Threshold")) {
                HStack {
                    Text("\(rule.zapMinutes) min")
                        .frame(width: 60, alignment: .leading)
                    Slider(value: zapBinding, in: 1...60, step: 1)
                }
                Text("LED fast-blinks 10 times")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                Button("Save") {
                    ruleStore.update(rule)
                    dismiss()
                }
                .frame(maxWidth: .infinity)

                Button("Delete", role: .destructive) {
                    ruleStore.delete(rule)
                    dismiss()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Edit Rule")
    }

    // Enforce zap >= warn + 1
    private var warnBinding: Binding<Double> {
        Binding(
            get: { Double(rule.warnMinutes) },
            set: { newVal in
                rule.warnMinutes = Int(newVal)
                if rule.zapMinutes <= rule.warnMinutes {
                    rule.zapMinutes = rule.warnMinutes + 1
                }
            }
        )
    }

    private var zapBinding: Binding<Double> {
        Binding(
            get: { Double(rule.zapMinutes) },
            set: { newVal in
                let val = max(Int(newVal), rule.warnMinutes + 1)
                rule.zapMinutes = val
            }
        )
    }
}
