import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: CleanMacViewModel
    @ObservedObject var updateManager: UpdateManager
    @ObservedObject var languageManager: LanguageManager
    @ObservedObject var appearanceManager: AppearanceManager
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                viewModel: viewModel,
                languageManager: languageManager,
                appearanceManager: appearanceManager
            )
                .navigationSplitViewColumnWidth(min: 280, ideal: 300, max: 360)
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
        .onReceive(NotificationCenter.default.publisher(for: .cleanMacToggleRecommended)) { _ in
            MainWindowController.show()
            viewModel.toggleRecommendedSelection()
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
        .alert(L("alert.clean_title"), isPresented: $viewModel.showCleanConfirmation) {
            Button(L("alert.cancel"), role: .cancel) {}
            Button(L("alert.clean"), role: .destructive) {
                Task { await viewModel.cleanConfirmed() }
            }
        } message: {
            Text(confirmationMessage)
        }
        .sheet(isPresented: $viewModel.showAbout) {
            AboutView(
                updateManager: updateManager,
                languageManager: languageManager,
                appearanceManager: appearanceManager
            )
            .preferredColorScheme(appearanceManager.preferredColorScheme)
        }
    }

    private var confirmationMessage: String {
        let total = ByteCountFormatter.string(from: viewModel.selectedTotalBytes)
        let permanent = ByteCountFormatter.string(from: viewModel.permanentReclaimBytes)
        if viewModel.includesRegeneratingSelection {
            return L("alert.confirm.regenerating", total, permanent)
        }
        if viewModel.includesDestructiveDeletion {
            return L("alert.confirm.destructive", total)
        }
        return L("alert.confirm.default", total)
    }
}

#Preview {
    ContentView(
        viewModel: CleanMacViewModel(),
        updateManager: UpdateManager(),
        languageManager: LanguageManager.shared,
        appearanceManager: AppearanceManager.shared
    )
}
