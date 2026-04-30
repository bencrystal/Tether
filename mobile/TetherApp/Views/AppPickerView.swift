import SwiftUI
#if canImport(FamilyControls)
import FamilyControls
#endif

struct AppPickerView: View {
    @EnvironmentObject var ruleStore: RuleStore
    @Environment(\.dismiss) private var dismiss

    #if canImport(FamilyControls)
    @State private var selection = FamilyActivitySelection()
    #endif

    @State private var manualName = ""

    var body: some View {
        NavigationStack {
            VStack {
                #if canImport(FamilyControls)
                familyActivityPickerContent
                #else
                manualEntryContent
                #endif
            }
            .navigationTitle("Add App")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addRules()
                        dismiss()
                    }
                }
            }
        }
    }

    #if canImport(FamilyControls)
    private var familyActivityPickerContent: some View {
        VStack(spacing: 16) {
            Text("Select apps to monitor")
                .font(.headline)
                .padding(.top)

            FamilyActivityPicker(selection: $selection)

            Text("Selected: \(selection.applicationTokens.count) app(s)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    #endif

    // Fallback for when FamilyControls entitlement isn't available
    private var manualEntryContent: some View {
        VStack(spacing: 16) {
            Text("FamilyControls not available")
                .font(.headline)
                .padding(.top)

            Text("Enter app name manually for testing")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField("App name (e.g. Instagram)", text: $manualName)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
        }
        .padding()
    }

    private func addRules() {
        #if canImport(FamilyControls)
        for token in selection.applicationTokens {
            // Encode the opaque token to Data for storage
            let tokenData = try? JSONEncoder().encode(token)
            let rule = AppRule(
                displayName: "App",  // FamilyControls doesn't expose app names directly
                appTokenData: tokenData
            )
            ruleStore.add(rule)
        }
        #else
        if !manualName.isEmpty {
            let rule = AppRule(displayName: manualName)
            ruleStore.add(rule)
        }
        #endif
    }
}
