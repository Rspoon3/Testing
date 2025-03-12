import SwiftUI
import CoreImage.CIFilterBuiltins

struct SnapchatQRCodeGenerator {
    /// Generates a Snapchat-style QR code with an avatar and decorative dots.
    /// - Parameters:
    ///   - avatar: The user's profile image.
    ///   - qrString: The text or URL to encode in the QR code.
    /// - Returns: A UIImage with the final QR code.
    static func generate(avatar: UIImage, qrString: String) -> UIImage {
        let qrImage = generateQRCode(from: qrString, withQuietZone: true) ?? UIImage()
        let qrWithAvatar = overlayAvatar(on: qrImage, avatar: avatar)
        return addSnapchatDots(to: qrWithAvatar)
    }

    /// Generates a QR code from a string with an optional quiet zone.
    private static func generateQRCode(from string: String, withQuietZone: Bool) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        
        // Increase quiet zone (padding) around QR code for the avatar space
        let transformScale: CGFloat = withQuietZone ? 12 : 10
        
        if let outputImage = filter.outputImage {
            let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: transformScale, y: transformScale))
            if let cgImage = context.createCGImage(transformed, from: transformed.extent) {
                return UIImage(cgImage: cgImage)
            }
        }
        return nil
    }

    /// Overlays the avatar in the center of the QR code without blocking important areas.
    private static func overlayAvatar(on qrImage: UIImage, avatar: UIImage) -> UIImage {
        let size = CGSize(width: 300, height: 300)
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        let rect = CGRect(origin: .zero, size: size)

        // Draw the QR code
        qrImage.draw(in: rect)

        // Define a clear safe zone for the avatar
        let avatarSize: CGFloat = 70
        let avatarRect = CGRect(
            x: (size.width - avatarSize) / 2,
            y: (size.height - avatarSize) / 2,
            width: avatarSize,
            height: avatarSize
        )

        // Add a white background circle to prevent QR code interference
        let avatarBackgroundSize: CGFloat = avatarSize * 1.2
        let avatarBackgroundRect = CGRect(
            x: (size.width - avatarBackgroundSize) / 2,
            y: (size.height - avatarBackgroundSize) / 2,
            width: avatarBackgroundSize,
            height: avatarBackgroundSize
        )

        UIColor.white.setFill()
        UIBezierPath(ovalIn: avatarBackgroundRect).fill()

        // Draw the avatar image
        avatar.draw(in: avatarRect, blendMode: .normal, alpha: 1.0)

        // Get the final image
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return finalImage ?? qrImage
    }

    /// Adds randomly placed dots around the QR code for a Snapchat-style effect.
    private static func addSnapchatDots(to image: UIImage) -> UIImage {
        let size = image.size
        let dotSize: CGFloat = 8
        let dotCount = 30 // Adjust for more/less dots

        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)

        // Draw the QR code first
        image.draw(in: CGRect(origin: .zero, size: size))

        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.black.cgColor) // Change dot color if needed

        for _ in 0..<dotCount {
            let x = CGFloat.random(in: 20...(size.width - 20))
            let y = CGFloat.random(in: 20...(size.height - 20))

            // Ensure dots do not overlap the avatar area
            let avatarSafeRadius: CGFloat = 50
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let distance = sqrt(pow(x - center.x, 2) + pow(y - center.y, 2))

            if distance > avatarSafeRadius {
                let rect = CGRect(x: x, y: y, width: dotSize, height: dotSize)
                context?.fillEllipse(in: rect) // Draw circular dots
            }
        }

        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return finalImage ?? image
    }
}
