//
//  LogViewController.swift
//  SwiftyFog_Example
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
			let range = NSMakeRange(self.log.text.characters.count, 0)
			self.log.scrollRangeToVisible(range)
			self.log.selectedRange = range
			self.log.insertText(str + "\n")
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
