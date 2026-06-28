import SwiftUI

struct UpdateAlertsModifier: ViewModifier {
    @ObservedObject var updateManager: UpdateManager

    func body(content: Content) -> some View {
        content
            .alert("Yeni sürüm mevcut", isPresented: $updateManager.showUpdateAlert) {
                Button("Sonra", role: .cancel) {
                    updateManager.skipUpdate()
                }
                Button("Güncelle") {
                    Task { await updateManager.installUpdate() }
                }
            } message: {
                if let update = updateManager.availableUpdate {
                    let current = AppVersion.current?.displayString ?? "?"
                    Text("CleanMac \(update.versionLabel) yayınlandı. Şu an \(current) kullanıyorsunuz.")
                }
            }
            .alert("Güncelleme", isPresented: $updateManager.showManualCheckAlert) {
                Button("Tamam", role: .cancel) {}
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

            Text("CleanMac güncelleniyor")
                .font(.headline)

            Text(updateManager.updateStatus ?? "Lütfen bekleyin…")
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
