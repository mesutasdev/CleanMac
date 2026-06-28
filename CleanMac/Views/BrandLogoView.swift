import SwiftUI

struct BrandLogoView: View {
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
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
    }
}
