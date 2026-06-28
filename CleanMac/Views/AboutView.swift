import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image("AppBrand")
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(radius: 8, y: 4)

            Text("CleanMac")
                .font(.title.weight(.semibold))

            Text("Sürüm \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Xcode ve Flutter geliştirici önbelleklerini güvenle temizler.\nSon build ve güncel cihaz sembolleri korunur.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            Button("Tamam") {
                dismiss()
            }
            .keyboardShortcut(.defaultAction)
            .controlSize(.large)
            .padding(.top, 8)
        }
        .padding(32)
        .frame(width: 340)
    }
}
