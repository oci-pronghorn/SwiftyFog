//
//  FiipLabel.swift
//  TrainControl
//
//  Created by David Giovannini on 10/15/17.
//  Copyright © 2017 Object Computing Inc. All rights reserved.
//
//  Based on FSDAirportFlipLabel by Felix Dumit on 3/25/14
//

import Foundation

private extension CharacterSet {
    /// extracting characters
    func allCharacters() -> [Character] {
        var allCharacters = [Character]()
        for plane: UInt8 in 0 ... 16 where hasMember(inPlane: plane) {
            for unicode in UInt32(plane) << 16 ..< UInt32(plane + 1) << 16 {
                if let uniChar = UnicodeScalar(unicode), contains(uniChar) {
                    allCharacters.append(Character(uniChar))
                }
            }
        }
        return allCharacters
    }

    /// building random string of desired length
    func randomString(length: Int) -> String {
        let charArray = allCharacters()
        let charArrayCount = UInt32(charArray.count)
        var randomString = ""
        for _ in 0 ..< length {
            randomString += String(charArray[Int(arc4random_uniform(charArrayCount))])
        }
        return randomString
    }
}

@IBDesignable
public class FlipLabel: UILabel {
	// The font size
    @IBInspectable public var textSize: CGFloat = 0
    
	// Optional fixed lenght for number of characters in label
    @IBInspectable public var fixedLength: Int = 0
	
	// The base number of flips a label will animate when changing between characters. Defaults to 10
    @IBInspectable public var numberOfFlips: Int = 0
	
	/* The range used to calculate the random number of flips an animating label will take.
	 * The value will be randomly selected between (numberOfFlips, (1 + numberOfFlipsRange) * numberOfFlips ).
     * Defaults to 1.0 => Default range is (numberOfFlips, 2*numberOfFlips)
     */
    @IBInspectable public var numberOfFlipsRange: Int = 0

	// Base flip velocity for changing labels. Defaults to 0.1
    @IBInspectable public var flipDuration: CGFloat = 0.0
	
	/* Range of flip duration span. The actual duration will be calculated randomly between
	 * (flipDuration, (1 + flipDurationRange) * flipDuration).
     * Defaults to 1.0 => Default range is (flipDuration, 2*flipDuration)
     */
    @IBInspectable public var flipDurationRange: CGFloat = 0.0
	
	// The flipping label's text color
    @IBInspectable public var flipTextColor: UIColor?
	
	// The flipping label's background color
    @IBInspectable public var flipBackGroundColor: UIColor?
	
	// Block called when the last label stops flipping
    public var finishedFlippingLabelsBlock: (() -> Void)? = nil
	
	// Block called when the labels start flipping
    public var startedFlippingLabelsBlock: (() -> Void)? = nil
	
    private var labels = [UILabel]()
    private var labelsInFlip: Int = 0
	
	public override init(frame: CGRect) {
        super.init(frame: frame)
        baseInit()
    }

	public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        baseInit()
    }

    private func baseInit() {
        self.textColor = UIColor.clear
        self.labels = [UILabel]()
        self.fixedLength = -1
        self.flipDuration = 0.1
        self.flipDurationRange = 0.0
        self.numberOfFlips = 1
        self.numberOfFlipsRange = 1
        self.flipBackGroundColor = UIColor.black
        self.flipTextColor = UIColor.white
        if self.textSize == 0 {
            self.textSize = 14
        }
        //[self updateText:self.text];
    }
	
	// If there are any labels flipping
    public var isFlipping: Bool  {
    	return labelsInFlip > 0
    }
	
	public override var text: String? {
		set {
			super.text = newValue
			updateText(newValue ?? "")
		}
		get {
			return super.text
		}
	}

	public override var intrinsicContentSize: CGSize {
		let charCount = max(fixedLength, text?.count ?? 0)
		return CGSize(width: CGFloat(charCount) * (textSize + 3.0) - 3.0, height: textSize + 2.0)
	}

	private func getOrCreateLabel(for index: Int) -> UILabel {
		let frame = CGRect(x: bounds.origin.x + (textSize + 3.0) * CGFloat(index), y: bounds.origin.y, width: textSize + 2, height: textSize + 2)
		var label: UILabel
		if index < labels.count {
			label = labels[index]
		}
		else {
			label = UILabel()
			labels.append(label)
			addSubview(label)
			label.backgroundColor = flipBackGroundColor
			label.textColor = flipTextColor
			label.textAlignment = .center
		}
		label.frame = frame
		label.font = UIFont.systemFont(ofSize: textSize)
		return label
	}

	private func updateText(_ text1: String) {
		resetLabels()
		//    self.textSize = self.frame.size.width / text.length - 2;
		let text = text1.uppercased()
		let len = max(fixedLength, text.count)
		for i in 0..<len {
			// get ith label
			let label = getOrCreateLabel(for: i)
			// get ith character
			var ichar = ""
			if i < text.count {
				ichar = "\(text[text.index(text.startIndex, offsetBy: i)])"
			}
			//if it is different than current animate flip
			label.isHidden = (ichar == "") && !(fixedLength > 0)
			if !(ichar == label.text) {
				animate(label, toLetter: ichar)
			}
		}
	}
	
	private func resetLabels() {
		labelsInFlip = 0
		for label: UILabel in labels {
			label.isHidden = true
		}
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
	
	func flip(_ label: UILabel, toLetter letter: String, inNumberOfFlips flipsToDo: Int) {
		let duration: TimeInterval = TimeInterval(flipDuration + (CGFloat(drand48()) * flipDurationRange * flipDuration))
		UIView.transition(with: label, duration: duration, options: .transitionFlipFromTop,
			animations: {
				label.text = flipsToDo == 1 ? letter : self.randomAlphabetCharacter()
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
	
	private func randomAlphabetCharacter() -> String {
    	return CharacterSet.alphanumerics.randomString(length: 1)
	}
}
