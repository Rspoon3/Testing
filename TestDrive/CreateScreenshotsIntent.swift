//
//  CreateScreenshotsIntent.swift
//  Testing
//
//  Created by Richard Witherspoon on 4/19/23.
//

import SwiftUI
import AppIntents
import Photos
import CollectionConcurrencyKit

struct CreateScreenshotsIntent: AppIntent {
    static let intentClassName = "CreateScreenshotsIntent"
    static var title: LocalizedStringResource = "Create Screenshots"
    static var description = IntentDescription("Creates screenshots with a device frame using the images passed in.")
    
    @Parameter(
        title: "Images",
        description: "The plain screenshots passed in that will be framed.",
        supportedTypeIdentifiers: ["public.image"],
        inputConnectionBehavior: .connectToPreviousIntentResult
    )
    var images: [IntentFile]
    
    @Parameter(
        title: "Copy to clipboard",
        description: "Will automatically save the last image to the clipboard."
    )
    var copyToClipboard: Bool
    
    @Parameter(
        title: "Save to files",
        description: "Will automatically save each image to the files app."
    )
    var saveToFiles: Bool
    
    @Parameter(
        title: "Save to photos",
        description: "Will automatically save each image to your photo library."
    )
    var saveToPhotos: Bool
    
    static var parameterSummary: some ParameterSummary {
        Summary("Create screenshots from \(\.$images)") {
            \.$copyToClipboard
            \.$saveToFiles
            \.$saveToPhotos
        }
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<[IntentFile]> {
        let screenshots = try await images.asyncCompactMap { file -> IntentFile? in
            let url = try await createDeviceFrame(using: file.data)
            
            var file = IntentFile(fileURL: url, type: .image)
            file.removedOnCompletion = true
            
            return file
        }
        
        return .result(value: screenshots)
    }
    
    private func createDeviceFrame(using data: Data) async throws -> URL {
        guard
            let screenshot = UIImage(data: data),
            let device = DeviceInfo.all.first(where: {$0.inputSize == screenshot.size}),
            let image = device.framed(using: screenshot),
            let data = image.pngData()
        else {
            throw DeviceFrameError.noData
        }
        
        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory
        let path = "\(UUID().uuidString).png"
        let temporaryDirectoryURL = temporaryDirectory.appending(path: path)
        
        try data.write(to: temporaryDirectoryURL)
        
        if copyToClipboard {
            UIPasteboard.general.image = image
        }
        
        if saveToFiles {
            let destination = URL.documentsDirectory.appending(path: path)
            try fileManager.copyItem(at: temporaryDirectoryURL, to: destination)
        }
        
        if saveToPhotos {
            try await PHPhotoLibrary.shared().performChanges {
                _ = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: temporaryDirectoryURL)
            }
        }
        
        return temporaryDirectoryURL
    }
}


//        let myImages = images.compactMap { file -> UIImage? in
//            guard
//                let screenshot = UIImage(data: file.data),
//                let device = Device.from(screenshot)
//            else {
//                return nil
//            }
//
//            return device.deviceFrame(using: screenshot)
//        }
//
//        let screenshot = myImages.stitchImages(isVertical: false)
//        let file = IntentFile(data: screenshot.pngData()!, filename: "merged", type: .image)
//
//
//        return .result(value: [file])
