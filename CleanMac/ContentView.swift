import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: CleanMacViewModel
    @ObservedObject var updateManager: UpdateManager
    @ObservedObject var languageManager: LanguageManager
    @ObservedObject var appearanceManager: AppearanceManager

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(
                viewModel: viewModel,
                languageManager: languageManager,
                appearanceManager: appearanceManager
            )
            .frame(width: 300)

            Divider()

            DetailView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            guard !viewModel.isInteractionLocked else { return }
            viewModel.toggleRecommendedSelection()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cleanMacSelectRecommended)) { _ in
            MainWindowController.show()
            guard !viewModel.isInteractionLocked else { return }
            viewModel.selectRecommended()
        }
        .onReceive(NotificationCenter.default.publisher(for: .cleanMacDeselectAll)) { _ in
            MainWindowController.show()
            guard !viewModel.isInteractionLocked else { return }
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
