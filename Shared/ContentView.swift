//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import PhotosUI

enum DeviceFrameError: LocalizedError {
    case noImage, noData
}

class ContentViewModel: ObservableObject {
    @Published var state: State = .idle
    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            if let imageSelection {
                state = .loading
                loadTransferable(from: imageSelection)
            }
        }
    }
    
    enum State {
        case idle
        case image(UIImage, URL)
        case loading
        case error(Error)
    }
    
    private func loadTransferable(from imageSelection: PhotosPickerItem) {
        Task {
            guard
                let data = try await imageSelection.loadTransferable(type: Data.self),
                let screenshot = UIImage(data: data)
            else {
                state = .error(DeviceFrameError.noData)
                return
            }
            
            await createDeviceFrame(using: screenshot)
        }
    }
    
    @MainActor
    private func createDeviceFrame(using screenshot: UIImage) {
        let devices = Bundle.main.decode([DeviceInfo].self, from: "Frames.json")

        guard
            let device = devices.first(where: {$0.inputSize == screenshot.size}),
            let image = device.framed(using: screenshot)
        else {
            state = .error(DeviceFrameError.noImage)
            return
        }
        
        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory
        let path = "\(UUID().uuidString).png"
        let url = temporaryDirectory.appending(path: path)
        
        guard let data = image.pngData() else {
            state = .error(DeviceFrameError.noData)
            return
        }
        
        do {
            try data.write(to: url)
            
            let documentsDirectory = URL.documentsDirectory
            let documentsURL = documentsDirectory.appending(path: path)
            
            try data.write(to: documentsURL)
        } catch {
            state = .error(error)
            return
        }
        
        state = .image(image, url)
    }
}

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    var body: some View {
        switch viewModel.state {
        case .error(let error):
            Text(error.localizedDescription)
        case .loading:
            ProgressView()
        case .idle:
            PhotosPicker(selection: $viewModel.imageSelection,
                         matching: .images,
                         photoLibrary: .shared()) {
                Text("Start")
            }
                         .buttonStyle(.borderless)
        case .image(let image, let url):
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding()
                
                ShareLink("Share", item: url)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
