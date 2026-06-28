import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: CleanMacViewModel
    @ObservedObject var updateManager: UpdateManager
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 240, ideal: 270, max: 320)
        } detail: {
            DetailView(viewModel: viewModel)
        }
        .frame(minWidth: 900, minHeight: 640)
        .updateAlerts(updateManager: updateManager)
        .onAppear {
            viewModel.refreshDiskSpace()
        }
        .task {
            await updateManager.checkForUpdates()
            await viewModel.scan()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cleanMacSelectRecommended)) { _ in
            MainWindowController.show()
            viewModel.selectRecommended()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cleanMacDeselectAll)) { _ in
            MainWindowController.show()
            viewModel.selectAll(false)
        }
        .onReceive(NotificationCenter.default.publisher(for: .cleanMacScan)) { _ in
            MainWindowController.show()
            Task { await viewModel.scan() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .cleanMacClean)) { _ in
            viewModel.requestClean()
        }
        .alert("Seçili dosyalar silinsin mi?", isPresented: $viewModel.showCleanConfirmation) {
            Button("İptal", role: .cancel) {}
            Button("Temizle", role: .destructive) {
                Task { await viewModel.cleanConfirmed() }
            }
        } message: {
            Text(confirmationMessage)
        }
        .sheet(isPresented: $viewModel.showAbout) {
            AboutView(updateManager: updateManager)
        }
    }

    private var confirmationMessage: String {
        let total = ByteCountFormatter.string(from: viewModel.selectedTotalBytes)
        if viewModel.includesRegeneratingSelection {
            return "\(total) silinecek. Bir kısmı bir sonraki build'de geri gelebilir. Kalıcı alan: \(ByteCountFormatter.string(from: viewModel.permanentReclaimBytes))."
        }
        if viewModel.includesDestructiveDeletion {
            return "\(total) silinecek. Son build veya güncel cihaz sembolleri de dahil."
        }
        return "\(total) kalıcı olarak silinecek. Son Xcode/Flutter build ve güncel iOS sembolleri korunur."
    }
}

#Preview {
    ContentView(viewModel: CleanMacViewModel(), updateManager: UpdateManager())
}
