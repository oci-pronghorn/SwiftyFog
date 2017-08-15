//
//  UIImagePickerController+.swift
//  DeviceProvisioning
//
//  Created by David Giovannini on 12/16/16.
//  Copyright © 2016 Object Computing Inc. All rights reserved.
//

import UIKit

public typealias UIImagePickerControllerCompletion = ((UIImage?, Bool)->())

extension UIImagePickerController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	private static var UIImagePickerController_completion: UInt8 = 0

    public var imageCompletion: UIImagePickerControllerCompletion? {
        get {
            let obj: Any? = objc_getAssociatedObject(self, &UIImagePickerController.UIImagePickerController_completion)
			return obj as? UIImagePickerControllerCompletion
        }
        set {
			self.delegate = self
			let obj: Any? = newValue
            objc_setAssociatedObject(self, &UIImagePickerController.UIImagePickerController_completion, obj, .OBJC_ASSOCIATION_RETAIN)
        }
    }
	
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage
		self.imageCompletion?(pickedImage, true)
	}

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		self.imageCompletion?(nil, false)
	}
}
