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
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }
}
