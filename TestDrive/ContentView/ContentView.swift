//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import SFSymbols

/// Main view for the photo ranking application.
struct ContentView: View {
    @StateObject private var viewModel = PhotoRankingViewModel()
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showPhotosPicker = false
    @State private var showFileImporter = false
    
    #if DEBUG
    @State private var showSettings = false
    #endif

    // MARK: - Body

    var body: some View {
        NavigationStack {
            InitialView(
                onShowPhotosPicker: {
                    showPhotosPicker = true
                },
                onShowDocumentPicker: {
                    showFileImporter = true
                }
            )
            .navigationTitle("Photo Ranker")
            #if DEBUG
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(symbol: .gearshape)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            #endif
            .sensoryFeedback(trigger: showPhotosPicker) { _, newValue in
                newValue ? .increase : nil
            }
            .sensoryFeedback(trigger: showFileImporter) { _, newValue in
                newValue ? .increase : nil
            }
            .photosPicker(
                isPresented: $showPhotosPicker,
                selection: $selectedItems,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: selectedItems) { _, newItems in
                Task {
                    await viewModel.loadPhotos(from: newItems)
                }
            }
            .fullScreenCover(isPresented: $viewModel.isComparing) {
                PhotoComparisonView(photos: viewModel.selectedPhotos) {
                    viewModel.reset()
                    selectedItems = []
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.image],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    Task {
                        await viewModel.loadPhotosFromFiles(urls: urls)
                    }
                case .failure(let error):
                    print("File import error: \(error.localizedDescription)")
                }
            }
            .alert(
                "Selection Error",
                isPresented: $viewModel.showError
            ) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

#Preview {
    ContentView()
}
