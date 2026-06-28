import AppKit
import SwiftUI

struct AboutView: View {
    @ObservedObject var updateManager: UpdateManager
    @ObservedObject var languageManager: LanguageManager
    @Environment(\.dismiss) private var dismiss

    private let iban = "TR51 0015 7000 0000 0088 1408 69"

    var body: some View {
        VStack(spacing: 16) {
            BrandLogoView(size: 112, cornerRadius: 24)

            Text(L("app.name"))
                .font(.title.weight(.semibold))

            Text(L("about.version", Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LanguageToggleView(languageManager: languageManager)

            Button(L("about.check_updates")) {
                Task { await updateManager.checkForUpdates(force: true) }
            }
            .controlSize(.regular)

            Text(L("about.description"))
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            VStack(spacing: 6) {
                Text(L("about.developer"))
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
                    Text(L("about.support"))
                        .font(.subheadline.weight(.semibold))
                    Link("Buy Me a Coffee", destination: URL(string: "https://buymeacoffee.com/mesutasdevw")!)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 6) {
                    Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 6) {
                        GridRow(alignment: .firstTextBaseline) {
                            supportLabel(L("about.account_holder"))
                            supportValue("Mesut As")
                        }
                        GridRow(alignment: .firstTextBaseline) {
                            supportLabel(L("about.bank"))
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
                                .help(L("about.copy_iban"))
                            }
                        }
                    }

                    Text(L("about.transfer_note"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .frame(maxWidth: .infinity)

            Button(L("about.ok")) {
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
