//
//  MenuBarContentView.swift
//  TestDrive
//

import SwiftUI

/// Popover content displayed when the user clicks the menu bar icon.
struct MenuBarContentView: View {
    @Bindable var viewModel: AppViewModel

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 420, height: 520)
        .onAppear { viewModel.bootstrap() }
    }

    // MARK: - Private Views

    private var header: some View {
        HStack {
            Image(systemName: "puzzlepiece.extension")
                .foregroundStyle(.tint)
            Text("Claude Plugin Toggler")
                .font(.headline)
            Spacer()
            Button {
                viewModel.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.isScanning)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.grantedRoots.isEmpty {
            emptyState
        } else if viewModel.directories.isEmpty {
            ScrollView { Text("No .claude folders found in the granted roots.") .padding() }
        } else {
            directoryList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Add a root directory to scan for .claude folders.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Add Root…") { viewModel.addRoot() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var directoryList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 4) {
                if let globalSettings = viewModel.globalSettings, !globalSettings.enabledPlugins.isEmpty {
                    GlobalSettingsRow(file: globalSettings)
                    Divider()
                }
                ForEach(viewModel.directories) { directory in
                    DirectoryRow(directory: directory, viewModel: viewModel)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var footer: some View {
        HStack {
            Button("Add Root…") { viewModel.addRoot() }
            Spacer()
            Menu("Roots (\(viewModel.grantedRoots.count))") {
                ForEach(viewModel.grantedRoots, id: \.self) { url in
                    Button {
                        viewModel.removeRoot(url)
                    } label: {
                        Text("Remove \(url.lastPathComponent)")
                    }
                }
            }
            .disabled(viewModel.grantedRoots.isEmpty)
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
