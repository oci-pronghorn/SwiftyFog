//
//  UserDefaults+.swift
//  TrainControl
//
//  Created by David Giovannini on 7/14/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import Foundation

extension UserDefaults {
	func loadDefaults() {
		let pathStr = Bundle.main.bundlePath
#if os(iOS)
		let settingsBundlePath = (pathStr as NSString).appendingPathComponent("Settings.bundle")
#elseif os(watchOS)
		let settingsBundlePath = (pathStr as NSString).appendingPathComponent("Settings-Watch.bundle")
#endif
		let finalPath = (settingsBundlePath as NSString).appendingPathComponent("Root.plist")
		let settingsDict = NSDictionary(contentsOfFile: finalPath)
		guard let prefSpecifierArray = settingsDict?.object(forKey: "PreferenceSpecifiers") as? [[String: Any]] else {
			return
		}

		var defaults = [String: Any]()

		for prefItem in prefSpecifierArray {
			guard let key = prefItem["Key"] as? String else {
				continue
			}
			if defaults[key] == nil {
				defaults[key] = prefItem["DefaultValue"]
			}
		}
		self.register(defaults: defaults)
	}
}
