//
//  PhotosAccess.swift
//  SwiftyFog
//
//  Created by David Giovannini on 12/16/16.
//  Copyright © 2016 Object Computing Inc. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

public protocol LocalizedStringConvertible {
	var localizedString: String { get }
}

extension String: LocalizedStringConvertible {
	public var localized: String {
		return self.localizedString
	}
	public var localizedString: String {
		return NSLocalizedString(self, comment: "")
	}
}

public extension RawRepresentable where RawValue: LocalizedStringConvertible {
	public var localizedString: String {
		return self.rawValue.localizedString
	}
}

public class PhotosAccess : NSObject, UIImagePickerControllerDelegate {
	private let title: String?
	private let root: UIViewController

	public init(title: String?, root: UIViewController) {
		self.title = title
		self.root = root
		super.init()
	}

	public func selectImage(hasCamera: Bool = false, hasLibrary: Bool = true, hasClear: Bool = false, completion: @escaping (UIImage?, Bool)->()) {
		let alert = UIAlertController(title: title?.localized, message: nil, preferredStyle: .alert)
		var handler: ((UIAlertAction) -> Swift.Void)? = nil
		if hasLibrary || UIImagePickerController.isSourceTypeAvailable( .camera) == false {
			if UIImagePickerController.isSourceTypeAvailable( .photoLibrary) {
				handler = { (action) in
					self.selectImage(sourceType: .photoLibrary, completion: completion)
				}
				let photosAction = UIAlertAction(title: "Library".localized, style: .default, handler: handler)
				alert.addAction(photosAction)
			}
		}
		if hasCamera {
			if UIImagePickerController.isSourceTypeAvailable( .camera) {
				handler = { (action) in
					self.selectImage(sourceType: .camera, completion: completion)
				}
				let cameraAction = UIAlertAction(title: "Camera".localized, style: .default, handler: handler)
				alert.addAction(cameraAction)
			}
		}
		if hasClear {
			handler = { (action) in
				completion(.none, true)
			}
			let removeAction = UIAlertAction(title: "Clear".localized, style: .destructive, handler: handler)
			alert.addAction(removeAction)
		}
		
		if alert.actions.count == 0 {
			completion(.none, false)
			return
		}
		
		if alert.actions.count == 1 {
			handler?(alert.actions[0])
			return
		}
		
		let cancelAction = UIAlertAction(title: "Cancel".localized, style: .cancel) { (action) in
			completion(.none, false)
		}
		alert.addAction(cancelAction)
		self.root.present(alert, animated: true)
	}

	public func selectImage(sourceType: UIImagePickerController.SourceType, completion: @escaping (UIImage?, Bool)->()) {
		check(perform: { access in
			if access {
				let imagePicker = UIImagePickerController()
				imagePicker.imageCompletion = { (image, selected) in
					self.root.dismiss(animated: true) {
						completion(image, selected)
					}
				}
				imagePicker.modalPresentationStyle = .fullScreen
				imagePicker.sourceType = sourceType
				imagePicker.mediaTypes = [kUTTypeImage as String]
				// TODO: make variable
				imagePicker.cameraDevice = .front
				self.root.present(imagePicker, animated: true, completion: nil)
			}
			else {
				completion(.none, false)
			}
		});
	}
	
	public func save(image: @autoclosure @escaping ()->UIImage, completion: ((Bool)->())? = nil) {
		check(perform: { access in
			if access {
				PHPhotoLibrary.shared().performChanges({
					PHAssetChangeRequest.creationRequestForAsset(from: image())
				}, completionHandler: { (success, error) -> Void in
					DispatchQueue.main.async {
						completion?(error != nil)
						self.alert(message: error != nil ? "An error has occured." : "Success")
					}
				})
			}
			else {
				completion?(false)
			}
		})
	}
	
	public func save(build: @escaping (@escaping (URL, Bool, Bool)->())->(), completion: ((Bool)->())? = nil) {
		check(perform: { access in
			if access {
				build() { (url, stopped, failed) in
					if stopped {
						try? FileManager.default.removeItem(at: url)
						if (failed) {
							self.alert(message: "An error has occured.")
						}
						completion?(false)
					}
					else {
						PHPhotoLibrary.shared().performChanges({
							PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
						}, completionHandler: { (success, error) -> Void in
							try? FileManager.default.removeItem(at: url)
							DispatchQueue.main.async {
								completion?(error != nil)
								self.alert(message: error != nil ? "An error has occured." : "Success")
							}
						})
					}
				}
			}
			else {
				completion?(false)
			}
		})
	}
	
	public func check(status: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(), perform: @escaping (Bool)->()) {
		switch status {
			case .authorized:
				perform(true)
				break
			case .denied:
				alert(message: "Access has been denied to photos.")
				perform(false)
				break
			case .notDetermined:
				PHPhotoLibrary.requestAuthorization { (status: PHAuthorizationStatus) in
					DispatchQueue.main.async {
						self.check(status: status, perform: perform)
					}
				}
				break
			case .restricted:
				alert(message: "Access has been restricted from photos.")
				perform(false)
				break
		}
	}
	
	func alert(message: String) {
		let alert = UIAlertController(title: title?.localized, message: message.localized, preferredStyle: .alert)
		let OKAction = UIAlertAction(title: "OK".localized, style: .default) { (action) in
		}
		alert.addAction(OKAction)
		root.present(alert, animated: true) {
		}
	}
}
