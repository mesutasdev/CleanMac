import AppKit
import SwiftUI

struct AboutView: View {
    @ObservedObject var updateManager: UpdateManager
    @Environment(\.dismiss) private var dismiss

    private let iban = "TR51 0015 7000 0000 0088 1408 69"

    var body: some View {
        VStack(spacing: 16) {
            BrandLogoView(size: 112, cornerRadius: 24)

            Text("CleanMac")
                .font(.title.weight(.semibold))

            Text("Sürüm \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Güncellemeleri Denetle") {
                Task { await updateManager.checkForUpdates(force: true) }
            }
            .controlSize(.regular)

            Text("Xcode ve Flutter geliştirici önbelleklerini güvenle temizler.\nSon build ve güncel cihaz sembolleri korunur.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            VStack(spacing: 6) {
                Text("Geliştirici: Mesut As")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Link("mesutas.com", destination: URL(string: "https://mesutas.com")!)
                    Text("|")
                        .foregroundStyle(.secondary)
                    Link("TechAs.co", destination: URL(string: "https://techas.co")!)
                }
                .font(.subheadline.weight(.medium))
            }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("Destek")
                        .font(.subheadline.weight(.semibold))
                    Link("Buy Me a Coffee", destination: URL(string: "https://buymeacoffee.com/mesutasdevw")!)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 6) {
                    Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                        GridRow(alignment: .firstTextBaseline) {
                            supportLabel("Hesap Sahibi")
                            supportValue("Mesut As")
                        }
                        GridRow(alignment: .firstTextBaseline) {
                            supportLabel("Banka")
                            supportValue("EnPara")
                        }
                        GridRow(alignment: .firstTextBaseline) {
                            supportLabel("IBAN")
                            HStack(spacing: 4) {
                                Text(iban)
                                    .font(.system(.caption2, design: .monospaced))
                                    .lineLimit(1)
                                    .textSelection(.enabled)

                                Button {
                                    copyToClipboard(iban.replacingOccurrences(of: " ", with: ""))
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption2)
                                }
                                .buttonStyle(.borderless)
                                .help("IBAN'ı kopyala")
                            }
                        }
                    }

                    Text("Açıklama: CleanMac destek (veya istediğiniz bir not)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .frame(maxWidth: .infinity)

            Button("Tamam") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
        }
        .padding(32)
        .frame(width: 400)
        .updateAlerts(updateManager: updateManager)
    }

    private func supportLabel(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func supportValue(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .textSelection(.enabled)
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
