//
//  TrainSelectorInterfaceController.swift
//  TrainConductor Extension
//
//  Created by David Giovannini on 8/4/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import WatchKit
import Foundation

class DiscoveredTrainCell: NSObject {
    @IBOutlet weak var label: WKInterfaceLabel!
	@IBInspectable var noTrainName: String = "Unselected"
	@IBInspectable var cellSpacingInset: CGFloat = 8
	@IBInspectable var selectedColor: UIColor = UIColor.gray
	@IBInspectable var unselectedColor: UIColor = UIColor.white
	
    func update(train: DiscoveredTrain, selected: Bool) {
        var presentedName = train.presentedName
        if presentedName.isEmpty {
        	presentedName = noTrainName
        }
		self.label.setText(presentedName)
		self.label.setTextColor(selected ? selectedColor : unselectedColor)
    }
}

class TrainSelectorInterfaceController: WKInterfaceController {

	@IBOutlet weak var tableView: WKInterfaceTable!
	
	var selectedTrain: String = ""
	
	var model: [DiscoveredTrain] = [] {
		didSet {
			self.tableView.setNumberOfRows(model.count, withRowType: "DiscoveredTrain")
			let rowCount = self.tableView.numberOfRows
			
			for i in 0..<rowCount {
				let cell = self.tableView.rowController(at: i) as! DiscoveredTrainCell
				let train = model[i]
				cell.update(train: train, selected: selectedTrain == train.trainName)
			}
		}
	}

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
