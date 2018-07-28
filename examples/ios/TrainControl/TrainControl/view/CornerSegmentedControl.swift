//
//  CornerSegmentedControl.swift
//  TrainControl
//
//  Created by David Giovannini on 7/28/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import UIKit

/*
 *	Will be a corner springloaded tab bar.
 */

@IBDesignable
class CornerSegmentedControl: UIButton {

	@IBInspectable
    var numberOfSegments: Int  = 0
	
	@IBInspectable
    var isMomentary: Bool = true

	@IBInspectable
    var selectedSegmentIndex: Int = -1
	
	@IBInspectable
    var actionImage: UIImage? = nil
	
    func insertSegment(withTitle title: String?, at segment: Int, animated: Bool) {
    }

    func insertSegment(with image: UIImage?, at segment: Int, animated: Bool){
    }

    func removeSegment(at segment: Int, animated: Bool){
    }

    func removeAllSegments(){
    }
	
    func setTitle(_ title: String?, forSegmentAt segment: Int) {
    }
	
    func titleForSegment(at segment: Int) -> String? {
    	return nil
    }
	
    func setImage(_ image: UIImage?, forSegmentAt segment: Int) {
    }

    func imageForSegment(at segment: Int) -> UIImage? {
    	return nil
    }
	
    func setEnabled(_ enabled: Bool, forSegmentAt segment: Int) {
    }

    func isEnabledForSegment(at segment: Int) -> Bool {
    	return false
    }
}
