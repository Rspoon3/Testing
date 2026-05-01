//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import QRCode

struct ContentView: View {
    @State private var image: UIImage?
    
    var body: some View {
        ZStack {
            ScrollingAvatarBackground()
                .opacity(0.04)
                .ignoresSafeArea()
                .onAppear {
                    guard let avatarImage = UIImage(named: "ricky") else { return }
                    
//                    let code = generateQRCode(from: "ricky Witherspoon", size: 200)!
//                    image = customizeQRCode(qrCode: code, profileImage: avatarImage, backgroundColor: .systemOrange, dotColor: .systemMint)
                    
                    let data = try! QRCode.build
                       .text("https://www.worldwildlife.org/about")
                       .foregroundColor(CGColor(srgbRed: 1, green: 0, blue: 0.6, alpha: 1))
                       .backgroundColor(UIColor.systemYellow.cgColor)
                       .logo(avatarImage.cgImage!, position: .circleCenter(inset: 0))
//                       .logo(image: avatarImage.cgImage!, unitRect: .init(origin: .init(x: 0.4, y: 0.4), size: .init(width: 0.2, height: 0.2)))
                       .onPixels.shape(.circle())
                       .eye.shape(.squircle())
                       .generate.image(dimension: 1200, representation: .png())
                    
                    image = UIImage(data: data)
                }
            
            VStack {
                AvatarView()
                    .padding(.bottom, 40)
                
                Text("It's nice to meet you!")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title)
                
                TextField("Username", text: .constant("Ricky"))
                    .textFieldStyle(.roundedBorder)
                
                TextField("Last Name", text: .constant("Witherspoon"))
                    .textFieldStyle(.roundedBorder)
                
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.black, lineWidth: 10)
                        )
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
import CoreImage
import UIKit

func generateQRCode(from string: String, size: CGFloat) -> UIImage? {
    let data = string.data(using: .ascii)
    guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("H", forKey: "inputCorrectionLevel") // High error correction

    if let outputImage = filter.outputImage {
        let transform = CGAffineTransform(scaleX: size / outputImage.extent.width,
                                          y: size / outputImage.extent.height)
        let scaledImage = outputImage.transformed(by: transform)
        return UIImage(ciImage: scaledImage)
    }
    return nil
}

func customizeQRCode(qrCode: UIImage, profileImage: UIImage?, backgroundColor: UIColor, dotColor: UIColor) -> UIImage? {
    let size = qrCode.size
    UIGraphicsBeginImageContextWithOptions(size, false, 0)
    
    // Draw background color
    backgroundColor.setFill()
    UIRectFill(CGRect(origin: .zero, size: size))
    
    // Draw QR code as a mask
    qrCode.draw(in: CGRect(origin: .zero, size: size), blendMode: .normal, alpha: 1.0)

    // Overlay a profile picture in the center (if provided)
    if let profile = profileImage {
        let profileSize = CGSize(width: size.width * 0.3, height: size.height * 0.3)
        let profileOrigin = CGPoint(x: (size.width - profileSize.width) / 2, y: (size.height - profileSize.height) / 2)
        profile.draw(in: CGRect(origin: profileOrigin, size: profileSize))
    }

    // Get the final image
    let finalImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return finalImage
}
func convertQRCodeToDots(ciImage: CIImage, size: CGSize) -> UIImage? {
    let context = CIContext()
    
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
    
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
        let scaleX = size.width / ciImage.extent.width
        let scaleY = size.height / ciImage.extent.height
        let pixelSize = min(scaleX, scaleY)
        
        let qrCodeData = cgImage.dataProvider!.data
        let pixelData = CFDataGetBytePtr(qrCodeData)!
        
        for y in 0..<Int(ciImage.extent.height) {
            for x in 0..<Int(ciImage.extent.width) {
                let pixelIndex = (y * Int(ciImage.extent.width) + x) * 4
                
                let red = pixelData[pixelIndex]
                if red == 0 { // QR code pixels are black
                    let dotRect = CGRect(
                        x: CGFloat(x) * pixelSize,
                        y: CGFloat(y) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )
                    
                    let dotPath = UIBezierPath(ovalIn: dotRect)
                    UIColor.black.setFill()
                    dotPath.fill()
                }
            }
        }
    }
}
