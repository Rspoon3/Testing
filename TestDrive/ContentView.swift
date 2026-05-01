//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var fileURL: URL?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var fileList: [FileInfo] = []
    @State private var showingFileList = false
    
    private let riveURL = URL(string: "https://prod-static-content.fetchrewards.com/content-service/spin_cta_pointling_animation_92bed5ced2.riv")!
    private let fileStorage = try! FileStorage(
        name: "RiveAssets",
        ttl: 60 // 1 minute for testing
    )
    
    var body: some View {
        VStack(spacing: 20) {
            Text("FileStorage Test")
                .font(.title)
                .padding()
            
            if isLoading {
                ProgressView("Downloading Rive file...")
            } else if let fileURL {
                VStack {
                    Text("✅ File downloaded successfully!")
                        .foregroundColor(.green)
                    Text("Local path: \(fileURL.lastPathComponent)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let errorMessage = errorMessage {
                Text("❌ Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button("Download Rive File") {
                Task {
                    await downloadFile()
                }
            }
            .disabled(isLoading)
            
            if fileURL != nil {
                Button("Clear Cache") {
                    Task {
                        await clearCache()
                    }
                }
            }
            
            Button("Show Storage Contents") {
                Task {
                    await loadFileList()
                    showingFileList = true
                }
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingFileList) {
            NavigationView {
                FileListView(files: fileList)
                    .navigationTitle("Storage Contents")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingFileList = false
                            }
                        }
                    }
            }
        }
    }
    
    private func downloadFile() async {
        isLoading = true
        errorMessage = nil
        fileURL = nil
        
        do {
            let localURL = try await fileStorage.fetchFile(from: riveURL)
            self.fileURL = localURL
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    private func clearCache() async {
        await fileStorage.clearExpiredFiles()
        self.fileURL = nil
    }
    
    private func loadFileList() async {
        do {
            fileList = try await fileStorage.listFiles()
        } catch {
            print("Failed to load file list: \(error)")
            fileList = []
        }
    }
}

struct FileListView: View {
    let files: [FileInfo]
    
    var body: some View {
        List {
            if files.isEmpty {
                Text("No files in storage")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(files, id: \.name) { file in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.name)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        HStack {
                            Label(file.formattedSize, systemImage: "doc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Label(RelativeDateTimeFormatter().localizedString(for: file.lastAccessed, relativeTo: Date()), systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
