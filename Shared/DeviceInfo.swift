//
//  Deviceswift
//  Testing
//
//  Created by Richard Witherspoon on 4/19/23.
//

import UIKit

struct DeviceInfo: Decodable {
    let deviceFrame: String
    let mergeMethod: MergeMethod
    let clipEdgesAmount: CGFloat?
    let inputSize: CGSize
    let scaledSize: CGSize?
    let offSet: CGPoint
    
    enum MergeMethod: String, Decodable {
        case singleOverlay
        case doubleOverlay
        case islandOverlay
    }
    
    func framed(using screenshot: UIImage) -> UIImage? {
        var screenshot = screenshot
        
        guard let frameImage = UIImage(named: deviceFrame) else {
            return nil
        }
        
        if let edgesAmount = clipEdgesAmount {
            screenshot = screenshot.clipEdgets(amount: edgesAmount)
        }
        
        if let scaledSize = scaledSize {
            let resizedScreenshot = screenshot.resized(to: scaledSize)
            return frameImage.merge(with: resizedScreenshot, offset: offSet)
        } else {
            switch mergeMethod {
            case .singleOverlay:
                return frameImage.merge(with: screenshot, offset: offSet)
            case .doubleOverlay:
                let image = frameImage.merge(with: screenshot, offset: offSet)
                return image.merge(with: frameImage, offset: .zero)
            case .islandOverlay:
                guard let noIsland = UIImage(named: "\(deviceFrame) Without Island") else {
                    return nil
                }
                
                let noIslandFrame = noIsland.merge(with: screenshot, offset: offSet)

                return noIslandFrame.merge(with: frameImage, offset: .zero)
            }
        }
    }
}
