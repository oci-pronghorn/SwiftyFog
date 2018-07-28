//
//  MetalPanelView.swift
//  TrainControl
//
//  Created by David Giovannini on 8/23/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//

import UIKit

@IBDesignable
class MetalPanelView: UIView {
	// TODO: IB designing cannpt find the image
	override init(frame: CGRect) {
		super.init(frame: frame)
		if let img = UIImage(named: "Metal") {
			self.backgroundColor = UIColor(patternImage: img)
		}
	}

	required public init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
		if let img = UIImage(named: "Metal") {
			self.backgroundColor = UIColor(patternImage: img)
		}
	}
	
	override func layoutSubviews() {
    	super.layoutSubviews()
    	self.setNeedsDisplay()
	}
}
