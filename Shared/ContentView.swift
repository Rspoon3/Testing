//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import ImageIO

struct ContentView: View {
    @State private var image: UIImage?
    
    
    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
            } else {
                Text("Hello, world!")
                    .padding()
            }
        }
        .task {
            try! await beginPlayback()
        }
    }
    
//    func addMetaData(image: UIImage) -> NSData?{
//       let sourceImage = image.cgImage
//       let data = UIImageJPEGRepresentation(image,1)
//       guard let source = CGImageSourceCreateWithData(data! as CFData, nil) else {return nil}
//       guard let type = CGImageSourceGetType(source) else {return nil}
//       let mutableData = NSMutableData(data: data!)
//       guard let destination = CGImageDestinationCreateWithData(mutableData, type, 1, nil) else { return nil}
//
//       let path = Bundle.main.url(forResource: "hasInjectGPanoImage", withExtension: "jpg")
//       let imageSource = CGImageSourceCreateWithURL(path! as CFURL, nil)
//       let imageProperties = CGImageSourceCopyMetadataAtIndex(imageSource!, 0, nil)
//
//       let mutableMetadata = CGImageMetadataCreateMutableCopy(imageProperties!)
//       CGImageMetadataSetValueMatchingImageProperty(mutableMetadata!, kCGImagePropertyTIFFDictionary, kCGImagePropertyTIFFMake, "Make e.g. Ricoh" as CFTypeRef)
//       CGImageMetadataSetValueMatchingImageProperty(mutableMetadata!, kCGImagePropertyTIFFDictionary, kCGImagePropertyTIFFModel, "Model e.g.Ricoh Theta S" as CFTypeRef)
//
//       CGImageMetadataSetValueMatchingImageProperty(mutableMetadata!, kCGImagePropertyGPSDictionary, kCGImagePropertyGPSLatitudeRef, "N" as CFTypeRef)
//       CGImageMetadataSetValueMatchingImageProperty(mutableMetadata!, kCGImagePropertyGPSDictionary, kCGImagePropertyGPSLatitude, "24.282646361029162" as CFTypeRef)
//       CGImageMetadataSetValueMatchingImageProperty(mutableMetadata!, kCGImagePropertyGPSDictionary, kCGImagePropertyGPSLongitudeRef, "E" as CFTypeRef)
//       CGImageMetadataSetValueMatchingImageProperty(mutableMetadata!, kCGImagePropertyGPSDictionary, kCGImagePropertyGPSLongitude, "121.00848124999993" as CFTypeRef)
//
//       let finalMetadata:CGImageMetadata = mutableMetadata!
//       CGImageDestinationAddImageAndMetadata(destination, sourceImage! , finalMetadata, nil)
//       guard CGImageDestinationFinalize(destination)else {return nil}
//       return mutableData;
//   }
    
    private func beginPlayback() async throws {
//        let url = URL(string: "https://media.giphy.com/media/xThuWu82QD3pj4wvEQ/giphy.gif")!
        let url = URL(string: "https://media.tenor.com/VVOA7SCKgmkAAAAC/test.gif")!

        let options: [CFString: Any] = [
            kCGImageAnimationLoopCount: 2
        ]

//        let url = URL(string: "https://giphy.com/clips/minecraft-microsoft-builder-minecraft-QxO6JEGaf3oTFDqqZJ")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let source: CGImageSource = CGImageSourceCreateWithData((data as! CFMutableData), nil)!
        let mutableData = NSMutableData(data: data)
        
        let type = CGImageSourceGetType(source)!
        let destination = CGImageDestinationCreateWithData(mutableData, type, 1, nil)!
        let sourceImage = UIImage(data: data)!.cgImage
        let imageProperties = CGImageSourceCopyMetadataAtIndex(source, 0, nil)

        let mutableMetadata = CGImageMetadataCreateMutableCopy(imageProperties!)

        CGImageMetadataSetValueMatchingImageProperty(mutableMetadata!, kCGImagePropertyGPSDictionary, kCGImagePropertyGPSLongitude, "121.00848124999993" as CFTypeRef)
        
        CGImageMetadataSetValueMatchingImageProperty(mutableMetadata!, kCGImagePropertyGIFDictionary, kCGImagePropertyGIFLoopCount, "10" as CFTypeRef)
        
        
        let finalMetadata:CGImageMetadata = mutableMetadata!

        
        CGImageDestinationAddImageAndMetadata(destination, sourceImage! , finalMetadata, nil)
        CGImageDestinationFinalize(destination)
        
        
        
        
        
        var metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as! [AnyHashable: Any]
        
//        print(metadata)
        print(finalMetadata)
        
        let test = CGAnimateImageDataWithBlock(data as CFData, options as CFDictionary) { index, cgImage, stop in
//            print(index, stop.pointee, cgImage.height)
            self.image = UIImage(cgImage: cgImage)
        }
        
//        let test = CGAnimateImageAtURLWithBlock(url as CFURL, nil) { index, cgImage, stop in
//            print(index, stop, cgImage.height)
//            self.image = UIImage(cgImage: cgImage)
//        }
        
        print(test)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
