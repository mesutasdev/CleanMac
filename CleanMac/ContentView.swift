import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: CleanMacViewModel
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(viewModel: viewModel)
                .navigationSplitViewColumnWidth(min: 240, ideal: 270, max: 320)
        } detail: {
            DetailView(viewModel: viewModel)
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            viewModel.refreshDiskSpace()
        }
        .task {
            await viewModel.scan()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cleanMacSelectRecommended)) { _ in
            viewModel.selectRecommended()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cleanMacDeselectAll)) { _ in
            viewModel.selectAll(false)
        }
        .onReceive(NotificationCenter.default.publisher(for: .cleanMacScan)) { _ in
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
            AboutView()
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
    ContentView(viewModel: CleanMacViewModel())
}
