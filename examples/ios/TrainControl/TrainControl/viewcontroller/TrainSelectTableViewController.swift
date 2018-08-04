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
}

protocol TrainSelectTableViewControllerDelegate: class {
	func selected(train: DiscoveredTrain?)
}

class TrainSelectTableViewController: UITableViewController {

	public weak var delegate: TrainSelectTableViewControllerDelegate?
	
	@IBInspectable var cellSpacingHeight: CGFloat = 8

	var model: [DiscoveredTrain] = [] {
		didSet {
			model.insert(DiscoveredTrain(trainName: "", displayName: "No Train"), at: 0)
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
		cell.label.text = model[indexPath.section].presentedName
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
