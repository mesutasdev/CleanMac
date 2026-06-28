import SwiftUI

/// Menü çubuğu ikonu her zaman yüklü olduğu için `openWindow` burada kaydedilir.
struct MenuBarLabel: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Image("AppLogo")
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fit)
            .frame(width: 18, height: 18)
            .onAppear {
                MainWindowController.registerOpenHandler {
                    openWindow(id: "main")
                }
            }
    }
}
