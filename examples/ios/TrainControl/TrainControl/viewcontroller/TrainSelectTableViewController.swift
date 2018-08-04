//
//  TrainSelectTableViewController.swift
//  TrainControl
//
//  Created by David Giovannini on 8/4/18.
//  Copyright © 2018 Object Computing Inc. All rights reserved.
//

import UIKit

class DiscoveredTrainCell: UITableViewCell {
	@IBOutlet weak var label: UILabel!
	@IBInspectable var noTrainName: String = "Unselected"
	@IBInspectable var cellSpacingInset: CGFloat = 8
	@IBInspectable var selectedColor: UIColor = UIColor.gray
	@IBInspectable var unselectedColor: UIColor = UIColor.white
	
	override func layoutSubviews() {
        super.layoutSubviews()
		contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 0, left: cellSpacingInset, bottom: 0, right: cellSpacingInset))
    }
	
    func update(train: DiscoveredTrain, selected: Bool) {
        var presentedName = train.presentedName
        if presentedName.isEmpty {
        	presentedName = noTrainName
        }
		self.label.text = presentedName
		self.label.textColor = selected ? selectedColor : unselectedColor
    }
}

protocol TrainSelectTableViewControllerDelegate: class {
	func selected(train: DiscoveredTrain?)
}

class TrainSelectTableViewController: UITableViewController {
	public weak var delegate: TrainSelectTableViewControllerDelegate?
	
	@IBInspectable var cellSpacingHeight: CGFloat = 8

	var model: [DiscoveredTrain] = [] {
		didSet {
			model.insert(DiscoveredTrain(trainName: "", displayName: nil), at: 0)
			if self.isViewLoaded {
				self.tableView.reloadData()
			}
		}
	}
	
	var selectedTrain: String = "" {
		didSet {
			if self.isViewLoaded {
				self.tableView.reloadData()
			}
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		self.tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.model.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrainCell", for: indexPath) as! DiscoveredTrainCell
        let train = model[indexPath.section]
		cell.update(train: train, selected: selectedTrain == train.trainName)
        return cell
    }
	
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    	self.dismiss(animated: true, completion: nil)
    	self.delegate?.selected(train: indexPath.section == 0 ? nil : model[indexPath.section])
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacingHeight
    }
	
    override var preferredContentSize: CGSize {
		get {
			let height = tableView.contentSize.height + cellSpacingHeight
			return CGSize(width: super.preferredContentSize.width, height: height)
		}
    	set {
    		super.preferredContentSize = newValue
		}
	}
}
