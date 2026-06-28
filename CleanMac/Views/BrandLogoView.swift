import SwiftUI

struct BrandLogoView: View {
    @Environment(\.colorScheme) private var colorScheme

    var size: CGFloat = 48
    var cornerRadius: CGFloat = 14

    var body: some View {
        Image("AppBrand")
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1)
            }
            .shadow(color: shadowColor, radius: 6, y: 3)
    }

    private var borderColor: Color {
        colorScheme == .dark ? .white.opacity(0.08) : .black.opacity(0.06)
    }

    private var shadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.18) : .black.opacity(0.12)
    }
}
