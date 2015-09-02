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
    var iconView: UIImageView?
    
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
    
    let themeColor = UIColor(red: 92/255, green: 126/255, blue: 149/255, alpha: 1)
    
    var containerView : UIView?
    var permissionButtons = [PermissionButton]()
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
                pc.dismissViewControllerAnimated(false, completion: {
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
            if let type = PermissionType(rawValue: key) {
                permissionTypes.append(type)
            }
        }

        self.present(parentController, types: permissionTypes) { success in
        }
    }
    
    
    class func present(onController: UIViewController, types: [PermissionType], completion: ((Bool)->Void)) {
        
        let controller = AppPermissionsViewController()
        controller.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.0)
        controller.parentController = onController
        
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "needDrawPermissionController")
        NSUserDefaults.standardUserDefaults().synchronize()

        controller.completion = completion
        controller.appPermissions = AppPermissions()
        
        let permissionsArray = controller.permissionsFromPlist(types)
        
        if controller.appPermissions!.isAuthorized(permissionsArray) {
            controller.completion?(true)
            return
        }
        
        controller.confureTransition()
        controller.addContainer(permissionsArray.count)
        controller.addCloseButton()
        controller.drawPermissions(permissionsArray)
        
        if controller.parentController!.navigationController != nil {
            controller.parentController!.navigationController!.presentViewController(controller, animated: false, completion: { () -> Void in
                controller.showContainerView()
            })
        } else {
            controller.parentController!.presentViewController(controller, animated: false, completion: { () -> Void in
                controller.showContainerView()
            })
        }
    }
    
    
    @objc private func updatePermissionsStatus() {
        
        var array = [String]()
        for permissionButton in permissionButtons {
            array.append(permissionButton.permission.type.rawValue)
        }
        NSUserDefaults.standardUserDefaults().setValue(array, forKey: "RestoredKeys")
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "needDrawPermissionController")
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    
    private func drawPermissions(permissionsArray: [Permission]) {
        
        var currentOffset = headerHeight
        for permission in permissionsArray {
            let button = PermissionButton(frame: CGRect(x: (containerWidth - buttonWidth) * 0.5, y: currentOffset, width: buttonWidth, height: buttonHeight), permission: permission)
            button.layer.cornerRadius = buttonHeight * 0.5
            
            let status = self.appPermissions!.status(forType: permission.type)
            if status == .Authorized {
                button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
                button.backgroundColor = themeColor
                
            } else {
                button.setTitleColor(themeColor, forState: UIControlState.Normal)
                button.layer.borderColor = themeColor.CGColor
                button.layer.borderWidth = 1
            }
            
            button.titleLabel?.font = UIFont(name: "HelveticaNeue-Medium", size: 15)
            button.setTitle(permission.title, forState: UIControlState.Normal)
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            button.titleEdgeInsets = UIEdgeInsetsMake(0, buttonHeight + 6, 0, 0)
            button.addTarget(self, action: "permissionButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            self.containerView?.addSubview(button)
            currentOffset += buttonHeight + itemsOffset
            
            let imageView = UIImageView(frame: CGRect(x: button.frame.origin.x + 6, y: button.frame.origin.y, width: buttonHeight, height: buttonHeight))
            imageView.contentMode = UIViewContentMode.Center
            let imagename = (status == .Authorized) ? "check_img" : permission.type.imageName()
            imageView.image = UIImage(named: imagename)
            self.containerView?.addSubview(imageView)
            button.iconView = imageView
            permissionButtons.append(button)
        }
    }
    
    
    // MARK: - Permission Buttons
    
    @objc private func permissionButtonPressed(button: PermissionButton) {
        
        self.appPermissions!.ask(forType: button.permission.type, callback: { requestStatus in
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
        
        if AppPermissionsViewController.lessThanEight() {
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
            button.backgroundColor = self.themeColor
            button.iconView?.image = UIImage(named: "check_img")
            
            var permissionArray = [Permission]()
            for permissionButton in self.permissionButtons {
                permissionArray.append(permissionButton.permission)
            }
            
            if self.appPermissions!.isAuthorized(permissionArray) {
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
        titleLabel.textColor = themeColor
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
    
    class func lessThanEight() -> Bool {
        
        if UIDevice.currentDevice().systemVersion.compare("8.0.0", options: NSStringCompareOptions.NumericSearch, range: nil, locale: nil) == NSComparisonResult.OrderedAscending {
            return true
        }
        return false
    }
    
    
    private func confureTransition() {
        
        if AppPermissionsViewController.lessThanEight() {
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
            data.setObject(permission.title, forKey: permission.type.rawValue)
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
            return [Permission]()
        } else {
            for type in needTypes {
                let title = data.objectForKey(type.rawValue) as? String
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
