import AppKit
import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    private let iban = "TR51 0015 7000 0000 0088 1408 69"

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                BrandLogoView(size: 112, cornerRadius: 24)

                Text("CleanMac")
                    .font(.title.weight(.semibold))

                Text("Sürüm \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Xcode ve Flutter geliştirici önbelleklerini güvenle temizler.\nSon build ve güncel cihaz sembolleri korunur.")
                    .font(.body)
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
                    Text("Destek")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)

                    Link("Buy Me a Coffee", destination: URL(string: "https://buymeacoffee.com/mesutasdevw")!)
                        .font(.subheadline)

                    VStack(alignment: .leading, spacing: 6) {
                        supportRow(label: "Hesap Sahibi", value: "Mesut As")
                        supportRow(label: "Banka", value: "EnPara")

                        HStack(alignment: .top) {
                            Text("IBAN")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 88, alignment: .leading)

                            Text(iban)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)

                            Button("Kopyala") {
                                copyToClipboard(iban.replacingOccurrences(of: " ", with: ""))
                            }
                            .buttonStyle(.borderless)
                            .font(.caption)
                            .controlSize(.small)
                        }

                        Text("Açıklama: CleanMac destek (veya istediğiniz bir not)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .frame(maxWidth: 320)

                Button("Tamam") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
                .padding(.top, 4)
            }
            .padding(32)
        }
        .frame(width: 380, height: 520)
    }

    private func supportRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 88, alignment: .leading)

            Text(value)
                .font(.caption)
                .textSelection(.enabled)
        }
    }

    private func copyToClipboard(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}
