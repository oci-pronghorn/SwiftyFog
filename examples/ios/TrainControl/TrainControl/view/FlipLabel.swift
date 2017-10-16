//
//  FlipLabel.swift
//  TrainControl
//
//  Created by David Giovannini on 10/15/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//
//  Based on FSDAirportFlipLabel by Felix Dumit on 3/25/14
//

import Foundation
import SwiftyFog_iOS

@IBDesignable
public class FlipLabel: UIView {
	// The font size
    @IBInspectable public var textSize: CGFloat = 14
    
	// Optional fixed lenght for number of characters in label
    @IBInspectable public var fixedLength: Int = 0 {
		didSet {
			if oldValue != fixedLength {
				invalidateIntrinsicContentSize()
				updateText()
			}
		}
	}
	
	// The base number of flips a label will animate when changing between characters. Defaults to 10
    @IBInspectable public var numberOfFlips: Int = 1
	
	/* The range used to calculate the random number of flips an animating label will take.
	 * The value will be randomly selected between (numberOfFlips, (1 + numberOfFlipsRange) * numberOfFlips ).
     */
    @IBInspectable public var numberOfFlipsRange: Int = 1

	// Base flip velocity for changing labels.
    @IBInspectable public var flipDuration: TimeInterval = 0.5
	
	/* Range of flip duration span. The actual duration will be calculated randomly between
	 * (flipDuration, (1 + flipDurationRange) * flipDuration).
     */
    @IBInspectable public var flipDurationRange: TimeInterval = 0.0
	
	// The flipping label's text color
    @IBInspectable public var flipTextColor = UIColor.white
	
	// The flipping label's background color
    @IBInspectable public var flipBackGroundColor = UIColor.black
	
	@IBInspectable public var text: String = "" {
		didSet {
			if fixedLength <= 0 && oldValue.count != text.count {
				invalidateIntrinsicContentSize()
			}
			updateText()
		}
	}
	
	// Block called when the last label stops flipping
    public var finishedFlippingLabelsBlock: (()->())? = nil
	
	// Block called when the labels start flipping
    public var startedFlippingLabelsBlock: (()->())? = nil
	
    private var labels = [UILabel]()
    private var labelsInFlip = 0
	
	public override init(frame: CGRect) {
        super.init(frame: frame)
    }

	public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

	public override var intrinsicContentSize: CGSize {
		let charCount = fixedLength > 0 ? fixedLength : text.count
		return CGSize(width: CGFloat(charCount) * (textSize + 3.0) - 3.0, height: textSize + 2.0)
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		updateText()
	}

	private func updateText() {
		labelsInFlip = 0
		let text = self.text.uppercased()
		let len = fixedLength > 0 ? fixedLength : text.count
		for i in 0..<len {
			// get ith label
			let label = getOrCreateLabel(for: i)
			// get ith character
			var ichar = ""
			if i < text.count {
				ichar = "\(text[text.index(text.startIndex, offsetBy: i)])"
			}
			//if it is different than current animate flip
			if !(ichar == label.text) {
				animate(label, toLetter: ichar)
			}
		}
		for i in len..<labels.count {
			labels[i].isHidden = true
		}
	}

	private func getOrCreateLabel(for index: Int) -> UILabel {
		let frame = CGRect(x: bounds.origin.x + (textSize + 3.0) * CGFloat(index), y: bounds.origin.y, width: textSize + 2, height: textSize + 2)
		var label: UILabel
		if index < labels.count {
			label = labels[index]
		}
		else {
			label = UILabel()
			label.isHidden = true
			labels.append(label)
			addSubview(label)
			label.textAlignment = .center
		}
		label.frame = frame
		label.backgroundColor = flipBackGroundColor
		label.textColor = flipTextColor
		label.font = UIFont.systemFont(ofSize: textSize)
		return label
	}
	
	private func animate(_ label: UILabel, toLetter letter: String) {
		// only 1 flip for space
		labelsInFlip += 1
		if (letter == " ") || (letter == "") {
			flip(label, toLetter: letter, inNumberOfFlips: 1)
		}
		else {
			// if it is the first label to start flipping, perform start block
			if labelsInFlip == 1 {
				startedFlippingLabelsBlock?()
			}
			let extraFlips = Int(arc4random() % UInt32(numberOfFlips * numberOfFlipsRange))
			// animate with between 10 to 20 flips
			flip(label, toLetter: letter, inNumberOfFlips: numberOfFlips + extraFlips)
		}
	}
	
	private func flip(_ label: UILabel, toLetter letter: String, inNumberOfFlips flipsToDo: Int) {
		label.isHidden = false
		let duration = flipDuration + (TimeInterval(drand48()) * flipDurationRange * flipDuration)
		UIView.transition(with: label, duration: duration, options: .transitionFlipFromTop,
			animations: {
				label.text = flipsToDo == 1 ? letter : CharacterSet.alphanumerics.randomString(length: 1)
			},
			completion: {(_ finished: Bool) in
				// if last flip
				if flipsToDo == 1 {
					// label has set its final value, so it stopped flipping
					self.labelsInFlip -= 1
					//if it is was last label flipping, perform finish block
					if self.labelsInFlip == 0 {
						self.finishedFlippingLabelsBlock?()
					}
				}
				else {
					self.flip(label, toLetter: letter, inNumberOfFlips: flipsToDo - 1)
				}
			})
	}
}
