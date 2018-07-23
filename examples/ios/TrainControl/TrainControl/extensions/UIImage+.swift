//
//  UIImage+.swift
//  TrainControl
//
//  Created by David Giovannini on 7/22/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import UIKit

@objc
public extension UIImage {
    @objc public func tinted(with color: UIColor) -> UIImage? {
		let s = self.size
#if os(iOS)
		UIGraphicsBeginImageContextWithOptions(s, false, UIScreen.main.scale)
#elseif os(watchOS)
		UIGraphicsBeginImageContextWithOptions(s, false, 0.0)
#endif
		defer {UIGraphicsEndImageContext()}
        let rect = CGRect(x: 0, y: 0, width: s.width, height: s.height)
		self.draw(in: rect)
        color.setFill()
		UIRectFillUsingBlendMode(rect, CGBlendMode.sourceAtop)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
