//
//  AppPermissionsViewController.swift
//  AppPermissions
//
//  Created by Олег Адамов on 21.08.15.
//  Copyright (c) 2015 Digital Expansion Inc. All rights reserved.
//

import UIKit


class PermissionButton: UIButton {
    
    let permission: Permission
    init(frame: CGRect, permission: Permission) {
        self.permission = permission
        super.init(frame: frame)
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



class AppPermissionsViewController: UIViewController, UIAlertViewDelegate {
    
    let containerWidth : CGFloat  = 280
    let headerHeight: CGFloat     = 140
    let bottomOffset: CGFloat     = 20
    let buttonHeight: CGFloat     = 44
    let buttonWidth: CGFloat      = 220
    let itemsOffset: CGFloat      = 18
    let labelTitleHeight: CGFloat = 30
    let labelDescHeight: CGFloat  = 50
    
    
    var containerView : UIView?
    var permissions: [Permission] = [Permission]()
    var appPermissions : AppPermissions?
    var parentController : UIViewController?
    var completion : ((Bool)->Void)?
    
    var applicationName : String {
        var appName = NSBundle.mainBundle().infoDictionary!["CFBundleDisplayName"] as? String
        if appName == nil {
            appName = NSBundle.mainBundle().infoDictionary!["CFBundleName"] as? String
            if appName == nil {
                appName = ""
            }
        }
        return appName!
    }
    let descriptionText = "We need a few things before you can start a battle"
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "updatePermissionsStatus", name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    class func restoreControllerIfNeeded(parentController : UIViewController) {
        
        if NSUserDefaults.standardUserDefaults().boolForKey("needDrawPermissionController") {
            if let pc = parentController.presentedViewController as? AppPermissionsViewController {
                pc.dismissViewControllerAnimated(false, completion: { () -> Void in
                    self.restoreController(parentController)
                })
            } else {
                restoreController(parentController)
            }
        }
        
    }
    
    private class func restoreController(parentController : UIViewController) {
        
        if !NSUserDefaults.standardUserDefaults().boolForKey("needDrawPermissionController") {
            return
        }
        
        let array = NSUserDefaults.standardUserDefaults().valueForKey("RestoredKeys") as? [String]
        if array == nil {
            return
        }
        
        var permissionTypes = [PermissionType]()
        for key in array! {
            if let type = Permission.permissionType(key) {
                permissionTypes.append(type)
            }
        }
        
        self.controller(parentController).present(permissionTypes) { (success) -> Void in
        }
    }
    
    
    class func controller(parentController : UIViewController) -> AppPermissionsViewController {
        
        let controller = AppPermissionsViewController()
        controller.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.0)
        controller.parentController = parentController
        return controller
    }
    
    
    func present(types: [PermissionType], completion: ((Bool)->Void)) {
        
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "needDrawPermissionController")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        if parentController == nil {
            return
        }
        self.completion = completion
        
        if types.count == 0 || contains(types, .CoreLocationAlways) || contains(types, .CoreLocationInUse) {
            self.appPermissions = AppPermissions(needLocationManager: true)
        } else {
            self.appPermissions = AppPermissions(needLocationManager: false)
        }
        self.permissions = permissionsFromPlist(types)
        if appPermissions!.isAllAuthorizedWithType(self.permissions) {
            self.completion?(true)
            return
        }
        
        confureTransition()
        addContainer(self.permissions.count)
        addCloseButton()
        drawPermissions()
        
        if parentController!.navigationController != nil {
            parentController!.navigationController!.presentViewController(self, animated: false, completion: { () -> Void in
                self.showContainerView()
            })
        } else {
            parentController!.presentViewController(self, animated: false, completion: { () -> Void in
                self.showContainerView()
            })
        }
    }
    
    
    @objc private func updatePermissionsStatus() {
        
        var array = [String]()
        for permission in permissions {
            let key = Permission.keyString(permission.type)
            array.append(key)
        }
        NSUserDefaults.standardUserDefaults().setValue(array, forKey: "RestoredKeys")
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "needDrawPermissionController")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    
    private func drawPermissions() {
        
        var currentOffset = headerHeight
        for permission in permissions {
            let button = PermissionButton(frame: CGRect(x: (containerWidth - buttonWidth) * 0.5, y: currentOffset, width: buttonWidth, height: buttonHeight), permission: permission)
            button.layer.cornerRadius = buttonHeight * 0.5
            
            let status = self.appPermissions!.askStatusForType(permission.type)
            if status == .Authorized {
                button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                button.backgroundColor = UIColor(red: 48/255, green: 215/255, blue: 143/255, alpha: 1.0)
                
            } else {
                button.setTitleColor(UIColor(white: 0.2, alpha: 1.0), forState: UIControlState.Normal)
                button.layer.borderColor = UIColor.blackColor().CGColor
                button.layer.borderWidth = 1
            }
            
            button.titleLabel?.font = UIFont(name: "HelveticaNeue-Medium", size: 15)
            button.setTitle(permission.title, forState: UIControlState.Normal)
            button.addTarget(self, action: "permissionButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            self.containerView?.addSubview(button)
            permission.button = button
            currentOffset += buttonHeight + itemsOffset
            
            let imageView = UIImageView(frame: CGRect(x: button.frame.origin.x, y: button.frame.origin.y, width: buttonHeight, height: buttonHeight))
            imageView.contentMode = UIViewContentMode.Center
            if status == .Authorized {
                imageView.image = UIImage(named: "ok")
            } else {
                imageView.image = UIImage(named: "mic")
            }
            self.containerView?.addSubview(imageView)
            permission.imageView = imageView
        }
    }
    
    
    // MARK: - Permission Buttons
    
    @objc private func permissionButtonPressed(button: PermissionButton) {
        
        self.appPermissions!.askForPermissionForType(button.permission.type, callback: { (requestStatus) -> () in
            switch requestStatus {
            case .AlreadyAuthorized:
                println("PERMISSIONS: nothing to do")
            case .Denied:
                println("PERMISSIONS: auth denied, settings")
            case .JustAuthorized:
                println("PERMISSIONS: auth success")
                self.buttonSetOn(button)
            case .NeedSettings:
                println("PERMISSIONS: need settings")
                self.showAlertView()
            }
        })
    }
    
    
    func showAlertView() {
        
        if lessThanEight() {
            UIAlertView(title: "", message: "The permission was rejected earlier!\nUse the settings to enable.", delegate: self, cancelButtonTitle: "Cancel").show()
        } else {
            UIAlertView(title: "", message: "The permission was rejected earlier!\nUse the settings to enable.", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Settings").show()
        }
    }
    
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        
        if buttonIndex != alertView.cancelButtonIndex {
            if let appString = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(appString)
            }
        }
    }
    
    
    private func buttonSetOn(button: PermissionButton) {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
            button.layer.borderWidth = 0
            button.backgroundColor = UIColor(red: 48/255, green: 215/255, blue: 143/255, alpha: 1.0)
            button.permission.imageView?.image = UIImage(named: "ok")
            
            if self.appPermissions!.isAllAuthorizedWithType(self.permissions) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.7 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
                    self.hideContainerView(true)
                }
            }
        })
    }
    
    
    // MARK: - Close Button
    
    private func addCloseButton() {
        
        let button = UIButton(frame: CGRect(x: containerWidth - 40, y: 10, width: 30, height: 30))
        button.setImage(UIImage(named: "close_btn"), forState: UIControlState.Normal)
        button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        button.addTarget(self, action: "closeButtonPressed", forControlEvents: UIControlEvents.TouchUpInside)
        self.containerView?.addSubview(button)
    }
    
    
    @objc private func closeButtonPressed() {
        
        hideContainerView(false)
    }
    
    
    // MARK: - White container view
    
    private func addContainer(permissionsCount: Int) {
        
        var whiteFrame = CGRectZero
        whiteFrame.size.width = containerWidth
        whiteFrame.origin.x = (self.view.frame.size.width - whiteFrame.size.width) * 0.5
        whiteFrame.size.height = headerHeight + CGFloat(permissionsCount) * (buttonHeight + itemsOffset) + bottomOffset
        whiteFrame.origin.y = self.view.frame.size.height
        
        containerView = UIView(frame: whiteFrame)
        containerView?.backgroundColor = UIColor.whiteColor()
        containerView?.layer.cornerRadius = 4
        self.view.addSubview(containerView!)
        
        let titleLabel = UILabel(frame: CGRect(x: (whiteFrame.size.width - buttonWidth) * 0.5, y: headerHeight * 0.5 - labelTitleHeight, width: buttonWidth, height: labelTitleHeight))
        titleLabel.textColor = UIColor(white: 0.1, alpha: 1.0)
        titleLabel.text = applicationName
        titleLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 24)!
        titleLabel.textAlignment = NSTextAlignment.Center
        containerView?.addSubview(titleLabel)
        
        let descriptionLabel = UILabel(frame: CGRect(x: (whiteFrame.size.width - buttonWidth) * 0.5, y: headerHeight * 0.5, width: buttonWidth, height: labelDescHeight))
        descriptionLabel.textColor = UIColor(white: 0.6, alpha: 1.0)
        descriptionLabel.font = UIFont(name: "HelveticaNeue", size: 15)
        descriptionLabel.text = descriptionText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = NSTextAlignment.Center
        containerView?.addSubview(descriptionLabel)
        
    }
    
    
    private func showContainerView() {
        
        if containerView == nil {
            return
        }
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.7)
            var whiteFrame: CGRect = self.containerView!.frame
            whiteFrame.origin.y = (self.view.frame.size.height - whiteFrame.size.height) * 0.5
            self.containerView?.frame = whiteFrame
        }) { (success) -> Void in
        }
    }
    
    
    private func hideContainerView(success: Bool) {
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.0)
            if self.containerView != nil {
                var whiteFrame = self.containerView!.frame
                whiteFrame.origin.y = self.view.frame.size.height
                self.containerView!.frame = whiteFrame
            }
        }) { (endAnim) -> Void in
            self.dismissViewControllerAnimated(false, completion: { () -> Void in
                self.completion?(success)
            })
        }
    }
    
    
    // MARK: - Transition Controllers
    
    private func lessThanEight() -> Bool {
        
        if UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch, range: nil, locale: nil) == NSComparisonResult.OrderedAscending {
            return true
        }
        return false
    }
    
    
    private func confureTransition() {
        
        if lessThanEight() {
            let appDelegate  = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.window?.rootViewController?.modalPresentationStyle = UIModalPresentationStyle.CurrentContext;
        } else {
            parentController!.providesPresentationContextTransitionStyle = true
            parentController!.definesPresentationContext = true
            self.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        }
    }
    
    
    // MARK: - File Operations
    
    class func configureIfNeeded(permissions: [Permission]) {
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as? String
        if  paths == nil {
            return
        }
        
        let path = paths!.stringByAppendingPathComponent("PermissionData.plist")
        let fileManager = NSFileManager.defaultManager()
        
        if fileManager.fileExistsAtPath(path) {
//            let data : NSMutableDictionary = NSMutableDictionary(contentsOfFile: path)!
//            for (key, value) in data {
//                println("\(key):  \(value)")
//            }
            return
        }
        var data : NSMutableDictionary = NSMutableDictionary()
        
        for permission in permissions {
            data.setObject(permission.title, forKey: Permission.keyString(permission.type))
        }
        data.writeToFile(path, atomically: true)
    }
    
    
    private func permissionsFromPlist(needTypes: [PermissionType]) -> [Permission] {
        
        var resultPermissions = [Permission]()
        
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as? String
        if  paths == nil {
            return [Permission]()
        }
        
        let path = paths!.stringByAppendingPathComponent("PermissionData.plist")
        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(path) {
            for type in needTypes {
                let permission = Permission(type: type, title: type.rawValue)
                resultPermissions.append(permission)
            }
            return resultPermissions
        }
        
        let data : NSMutableDictionary = NSMutableDictionary(contentsOfFile: path)!
        
        if needTypes.count == 0 {
            for (key, title) in data {
                let type = Permission.permissionType(key as! String)
                if type != nil {
                    let permission = Permission(type: type!, title: title as! String)
                    resultPermissions.append(permission)
                }
            }
        } else {
            for type in needTypes {
                let title = data.objectForKey(Permission.keyString(type)) as? String
                if title != nil {
                    let permission = Permission(type: type, title: title!)
                    resultPermissions.append(permission)
                } else {
                    let permission = Permission(type: type, title: type.rawValue)
                    resultPermissions.append(permission)
                }
            }
        }
        return resultPermissions
    }

}
