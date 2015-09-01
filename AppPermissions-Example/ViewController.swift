//
//  ViewController.swift
//  AppPermissions-Example
//
//  Created by Олег Адамов on 01.09.15.
//  Copyright (c) 2015 Digital Expansion Inc. All rights reserved.
//

import UIKit

class PermissionSwitch : UISwitch {
    var type: PermissionType?
}

class ViewController: UITableViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "doneButtonPressed")
        navigationItem.title = "AppPermissions"
    }
    
    
    @objc private func doneButtonPressed() {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.min
    }


}

