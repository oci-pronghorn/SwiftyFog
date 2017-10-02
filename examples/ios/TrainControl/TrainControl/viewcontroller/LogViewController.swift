//
//  LogViewController.swift
//  TrainControl
//
//  Created by David Giovannini on 8/28/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit

class LogViewController: UIViewController {
	@IBOutlet weak var log: UITextView!
	
	func onLog(_ str: String) {
		DispatchQueue.main.async {
			let _ = self.view
			let range = NSMakeRange(self.log.text.count, 0)
			self.log.scrollRangeToVisible(range)
			self.log.selectedRange = range
			self.log.insertText(str + "\n")
		}
	}
}
