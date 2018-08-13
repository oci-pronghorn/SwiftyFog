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
	private var model: [DiscoveredTrain] = []
	private var isActive = false
	
	internal static weak var shared: TrainSelectorInterfaceController!
	
	override init() {
		super.init()
		TrainSelectorInterfaceController.shared = self
	}

    override func willActivate() {
        super.willActivate()
        isActive = true
		reloadData()
    }
	
    override func didDeactivate() {
        super.didDeactivate()
        isActive = false
	}
	
    internal func reloadData() {
    	if self.isActive {
			self.model = TrainInterfaceController.shared.discovery.snapshop
			let selectedTrainName = TrainInterfaceController.shared.discoveredTrain?.trainName ?? ""
			model.insert(DiscoveredTrain(trainName: "", displayName: nil), at: 0)
			self.tableView.setNumberOfRows(model.count, withRowType: "DiscoveredTrain")
		
			for i in 0..<model.count {
				let cell = self.tableView.rowController(at: i) as! DiscoveredTrainCell
				let train = model[i]
				let selectedTrainName = selectedTrainName
				cell.update(train: train, selected: selectedTrainName == train.trainName)
			}
		}
    }
	
	override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
		TrainInterfaceController.shared.discoveredTrain = rowIndex == 0 ? nil : model[rowIndex]
		TrainInterfaceController.shared.becomeCurrentPage()
	}
}
