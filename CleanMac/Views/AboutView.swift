import AppKit
import SwiftUI

struct AboutView: View {
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
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        supportLabel("IBAN")
                        HStack(alignment: .top, spacing: 6) {
                            Text(iban)
                                .font(.system(.caption, design: .monospaced))
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)

                            Button {
                                copyToClipboard(iban.replacingOccurrences(of: " ", with: ""))
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .help("IBAN'ı kopyala")
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
