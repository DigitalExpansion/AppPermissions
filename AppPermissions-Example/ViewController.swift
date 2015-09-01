//
//  ViewController.swift
//  AppPermissions-Example
//
//  Created by Олег Адамов on 01.09.15.
//  Copyright (c) 2015 Digital Expansion Inc. All rights reserved.
//

import UIKit

extension Array {
    mutating func remove <U: Equatable> (object: U) {
        for i in stride(from: self.count-1, through: 0, by: -1) {
            if let element = self[i] as? U {
                if element == object {
                    self.removeAtIndex(i)
                }
            }
        }
    }
}

class PermissionCell: UITableViewCell {
    
    @IBOutlet weak var permissionLabel: UILabel!
    @IBOutlet weak var permissionSwitch: UISwitch!
    
}


class ViewController: UITableViewController {

    
    let typesData: [PermissionType] = [.AssetsLibrary, .Camera, .Calendars, .Contacts, .LocationAlways, .LocationInUse, .Microphone, .Notifications, .Reminders]
    var needTypes = [PermissionType]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneButtonPressed")
        navigationItem.title = "AppPermissions"
    }
    
    
    @objc private func doneButtonPressed() {
        
        
        AppPermissionsViewController.controller(self).present(needTypes, completion: { (success) -> Void in
            self.navigationItem.title = success ?  "Success" : "Failure"
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - UITableViewDataSource
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.min
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return typesData.count
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PermissionCell") as! PermissionCell
        let permissionType = typesData[indexPath.row]
        cell.permissionLabel.text = permissionType.rawValue
        cell.permissionSwitch.tag = indexPath.row
        cell.permissionSwitch.addTarget(self, action: "switchValueChanged:", forControlEvents: UIControlEvents.ValueChanged)
        if contains(needTypes, permissionType) {
            cell.permissionSwitch.setOn(true, animated: false)
        }
        
        return cell
    }
    
    
    @objc private func switchValueChanged(sender: UISwitch) {
        let type = typesData[sender.tag]
        let isContained = contains(needTypes, type)
        if sender.on  && !isContained {
            needTypes.append(type)
        } else if !sender.on && isContained {
            needTypes.remove(type)
        }
        
    }
    
}

