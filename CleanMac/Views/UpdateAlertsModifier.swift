import SwiftUI

struct UpdateAlertsModifier: ViewModifier {
    @ObservedObject var updateManager: UpdateManager

    func body(content: Content) -> some View {
        content
            .alert(L("update.available_title"), isPresented: $updateManager.showUpdateAlert) {
                Button(L("update.later"), role: .cancel) {
                    updateManager.skipUpdate()
                }
                Button(L("update.install")) {
                    Task { await updateManager.installUpdate() }
                }
            } message: {
                if let update = updateManager.availableUpdate {
                    let current = AppVersion.current?.displayString ?? "?"
                    Text(L("update.message", update.versionLabel, current))
                }
            }
            .alert(L("update.title"), isPresented: $updateManager.showManualCheckAlert) {
                Button(L("about.ok"), role: .cancel) {}
            } message: {
                Text(updateManager.manualCheckMessage ?? "")
            }
            .sheet(isPresented: $updateManager.isUpdating) {
                UpdateProgressView(updateManager: updateManager)
            }
    }
}

struct UpdateProgressView: View {
    @ObservedObject var updateManager: UpdateManager

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text(L("update.progress_title"))
                .font(.headline)

            Text(updateManager.updateStatus ?? L("update.please_wait"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(width: 320)
        .interactiveDismissDisabled()
    }
}

extension View {
    func updateAlerts(updateManager: UpdateManager) -> some View {
        modifier(UpdateAlertsModifier(updateManager: updateManager))
    }
}
