import SwiftUI
import SFSymbols

/// Displays persistent debug logs for diagnosing issues when not connected to Xcode.
struct DebugLogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = DebugLogViewModel()
    @State private var showingShareSheet = false
    @State private var shareURL: URL?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statsHeader

                filterField

                logContent
            }
            .navigationTitle("Debug Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            viewModel.refresh()
                        } label: {
                            Label("Refresh", symbol: .arrowClockwise)
                        }

                        Button {
                            viewModel.copyLogs()
                        } label: {
                            Label("Copy All", symbol: .docOnDoc)
                        }

                        Button {
                            if let url = viewModel.shareLogs() {
                                shareURL = url
                                showingShareSheet = true
                            }
                        } label: {
                            Label("Share", symbol: .squareAndArrowUp)
                        }

                        Divider()

                        Button(role: .destructive) {
                            viewModel.clearLogs()
                        } label: {
                            Label("Clear Logs", symbol: .trash)
                        }
                    } label: {
                        Image(symbol: .ellipsisCircle)
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = shareURL {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    // MARK: - Private Views

    private var statsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(viewModel.logCount) entries")
                    .font(.headline)
                Text(viewModel.logFileSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                viewModel.refresh()
            } label: {
                Image(symbol: .arrowClockwise)
            }
            .disabled(viewModel.isRefreshing)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }

    private var filterField: some View {
        HStack {
            Image(symbol: .magnifyingglass)
                .foregroundStyle(.secondary)
            TextField("Filter logs...", text: $viewModel.filterText)
                .textFieldStyle(.plain)
            if !viewModel.filterText.isEmpty {
                Button {
                    viewModel.filterText = ""
                } label: {
                    Image(symbol: .xmarkCircleFill)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var logContent: some View {
        ScrollView {
            ScrollViewReader { proxy in
                Text(viewModel.filteredLogs)
                    .font(.system(.caption, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .id("bottom")
                    .onAppear {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - ShareSheet

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    DebugLogView()
}
