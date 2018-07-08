//
//  UIImage+Fog.swift
//  SwiftyFog
//
//  Created by David Giovannini on 7/26/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit

extension UIImage {
	var fogColorSpace: FogColorSpace {
		return .rgba
	}

	public func fogScanPixels(scan: (Int, Int, [CGFloat])->Bool) {
		if let img = self.cgImage, let provider = img.dataProvider {
			let w = Int(size.width)
			let h = Int(size.height)
			let pixelData = provider.data
			let bytesPerPixel = Int((CGFloat(img.bitsPerPixel) / 8.0).rounded(.up))
			let bytesPerRow = Int(img.bytesPerRow)
			let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
			var pixel = [CGFloat](repeating: 0.0, count: 4)
			for x in 0..<w {
				for y in 0..<h {
					let pixelInfo: Int = (bytesPerPixel * y) + (x * bytesPerRow)
					pixel[0] = CGFloat(data[pixelInfo+0]) / 255.0
					pixel[1] = CGFloat(data[pixelInfo+1]) / 255.0
					pixel[2] = CGFloat(data[pixelInfo+2]) / 255.0
					pixel[3] = CGFloat(data[pixelInfo+3]) / 255.0
					if scan(x, y, pixel) == false {
						return
					}
				}
			}
		}
	}

	public func fogResize(_ size: CGSize) -> UIImage? {
		var returnImage: UIImage?
		var scaleFactor: CGFloat = 1.0
		var scaledWidth = size.width
		var scaledHeight = size.height
		var thumbnailPoint = CGPoint()
		
		if !self.size.equalTo(size) {
			let widthFactor = size.width / self.size.width
			let heightFactor = size.height / self.size.height
			
			if widthFactor > heightFactor {
				scaleFactor = widthFactor
			} else {
				scaleFactor = heightFactor
			}
			
			scaledWidth = self.size.width * scaleFactor
			scaledHeight = self.size.height * scaleFactor
			
			if widthFactor > heightFactor {
				thumbnailPoint.y = (size.height - scaledHeight) * 0.5
			} else if widthFactor < heightFactor {
				thumbnailPoint.x = (size.width - scaledWidth) * 0.5
			}
		}
		
		UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
		
		var thumbnailRect = CGRect()
		thumbnailRect.origin = thumbnailPoint
		thumbnailRect.size.width = scaledWidth
		thumbnailRect.size.height = scaledHeight
		
		self.draw(in: thumbnailRect)
		returnImage = UIGraphicsGetImageFromCurrentImageContext()
		
		UIGraphicsEndImageContext()
		
		return returnImage
	}
	
   public func fogFixedOrientation() -> UIImage {
	if imageOrientation == UIImage.Orientation.up {
            return self
        }

        var transform: CGAffineTransform = CGAffineTransform.identity

        switch imageOrientation {
        case UIImage.Orientation.down, UIImage.Orientation.downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
            break
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
            break
        case UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
            break
        case UIImage.Orientation.up, UIImage.Orientation.upMirrored:
            break
        }

        switch imageOrientation {
        case UIImage.Orientation.upMirrored, UIImage.Orientation.downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
            break
        case UIImage.Orientation.leftMirrored, UIImage.Orientation.rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case UIImage.Orientation.up, UIImage.Orientation.down, UIImage.Orientation.left, UIImage.Orientation.right:
            break
        }

        let ctx: CGContext = CGContext(data: nil,
                                       width: Int(size.width),
                                       height: Int(size.height),
                                       bitsPerComponent: self.cgImage!.bitsPerComponent,
                                       bytesPerRow: 0,
                                       space: self.cgImage!.colorSpace!,
                                       bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!

        ctx.concatenate(transform)

        switch imageOrientation {
        case UIImage.Orientation.left, UIImage.Orientation.leftMirrored, UIImage.Orientation.right, UIImage.Orientation.rightMirrored:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            break
        }

        let cgImage: CGImage = ctx.makeImage()!

        return UIImage(cgImage: cgImage)
    }
}
