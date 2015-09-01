//
//  AppPermissions.swift
//  AppPermissions
//
//  Created by Олег Адамов on 24.08.15.
//  Copyright (c) 2015 Digital Expansion Inc. All rights reserved.
//

import UIKit
import AssetsLibrary
import AVFoundation
import EventKit
import AddressBook
import CoreLocation


class Permission: NSObject {
    
    let type : PermissionTypes
    let title : String
    var button: UIButton?
    var imageView: UIImageView?
    
    init(type: PermissionTypes, title: String) {
        
        self.type = type
        self.title = title
        super.init()
    }
    
    class func keyString(type: PermissionTypes) -> String {
        switch type {
        case .AssetLibrary:
            return "asset_library_key"
        case .Camera:
            return "camera_key"
        case .Calendars:
            return "calendars_key"
        case .Contacts:
            return "contacts_key"
        case .CoreLocationAlways:
            return "location_always_key"
        case .CoreLocationInUse:
            return "location_inuse_key"
        case .Microphone:
            return "microphone_key"
        case .Notifications:
            return "notifications_key"
        case .Reminders:
            return "reminders_key"
        case .Photos:
            return "photos_key"
        }
    }
    
    class func permissionType(keyString : String) -> PermissionTypes? {
        switch keyString {
        case "asset_library_key":
            return .AssetLibrary
        case "camera_key":
            return .Camera
        case "calendars_key":
            return .Calendars
        case "contacts_key":
            return .Contacts
        case "location_always_key":
            return .CoreLocationAlways
        case "location_inuse_key":
            return .CoreLocationInUse
        case "microphone_key":
            return .Microphone
        case "notifications_key":
            return .Notifications
        case "reminders_key":
            return .Reminders
        case "photos_key":
            return .Photos
        default:
            return nil
        }
    }
}


enum PermissionTypes : String {
    case AssetLibrary = "Camera Roll"               //
    case Camera = "Camera"                          // Record Video
    case Calendars = "Calendars"                    //
    case Contacts = "Contacts"                      //
    case CoreLocationAlways = "Location Always"     //
    case CoreLocationInUse = "Location In Use"      //
    case Microphone = "Microphone"                  //
    case Notifications = "Notifications"            //
    case Reminders = "Reminders"                    //  EventKit Framework
    case Photos = "Photos"                          //  iOS 8 (Photo Framework)
}


enum StatusTypes {
    case Authorized
    case Denied
    case NotDetermined
    case Restricted
}


enum RequestStatusCallback {
    case AlreadyAuthorized
    case Denied
    case JustAuthorized
    case NeedSettings
}



class AppPermissions: NSObject, CLLocationManagerDelegate {
    
    var locationManager: CLLocationManager?
    var tempBlock: ((RequestStatusCallback) -> ())?
    
    init(needLocationManager: Bool) {
        super.init()
        if needLocationManager {
            locationManager = CLLocationManager()
        }
    }
    
    
    func askStatusForType(type: PermissionTypes) -> StatusTypes {
        
        switch type {
        case .AssetLibrary:
            return AssetsLibraryPermissionStatus()
        case .Camera:
            return CameraPermissionStatus()
        case .Calendars:
            return CalendarPermissionStatus()
        case .Contacts:
            return ContactsPermissionStatus()
        case .Microphone:
            return MicrophonePermissionStatus()
        case .Notifications:
            return NotificationsPermissionStatus()
        case .CoreLocationAlways:
            return LocationAlwaysPermissionStatus()
        case .CoreLocationInUse:
            return LocationInUsePermissionStatus()
        default:
            break
        }
        
        return .NotDetermined
    }
    
    
    func isAllAuthorizedWithType(permissions: [Permission]) -> Bool {
        
        for permission in permissions {
            let status = askStatusForType(permission.type)
            if status != .Authorized {
                return false
            }
        }
        return true
    }
    
    
    func askForPermissionForType(type: PermissionTypes, callback: ((RequestStatusCallback) -> ())) {
        
        switch type {
        case .AssetLibrary:
            if AssetsLibraryPermissionStatus() == .NotDetermined {
                AssetsLibraryAskPermission(callback)
            } else if AssetsLibraryPermissionStatus() == .Authorized {
                callback(RequestStatusCallback.AlreadyAuthorized)
            } else {
                callback(RequestStatusCallback.NeedSettings)
            }
        
        case .Camera:
            if CameraPermissionStatus() == .NotDetermined {
                CameraAskPermission(callback)
            } else if CameraPermissionStatus() == .Authorized {
                callback(RequestStatusCallback.AlreadyAuthorized)
            } else {
                callback(RequestStatusCallback.NeedSettings)
            }
            
        case  .Calendars:
            if CalendarPermissionStatus() == .NotDetermined {
                CalendarAskPermission(callback)
            } else if CalendarPermissionStatus() == .Authorized {
                callback(RequestStatusCallback.AlreadyAuthorized)
            } else {
                callback(RequestStatusCallback.NeedSettings)
            }
            
        case .Contacts:
            if ContactsPermissionStatus() == .NotDetermined {
                ContactsAskPermission(callback)
            } else if ContactsPermissionStatus() == .Authorized {
                callback(RequestStatusCallback.AlreadyAuthorized)
            } else {
                callback(RequestStatusCallback.NeedSettings)
            }
            
        case .Microphone:
            if MicrophonePermissionStatus() == .NotDetermined {
                MicrophoneAskPermission(callback)
            } else if MicrophonePermissionStatus() == .Authorized {
                callback(RequestStatusCallback.AlreadyAuthorized)
            } else {
                callback(RequestStatusCallback.NeedSettings)
            }
            
        case .Notifications:
            if NotificationsPermissionStatus() == .NotDetermined {
                NotificationsAskPermission(callback)
            } else if NotificationsPermissionStatus() == .Authorized {
                callback(RequestStatusCallback.AlreadyAuthorized)
            } else {
                callback(RequestStatusCallback.NeedSettings)
            }
            
        case .CoreLocationAlways:
            if LocationAlwaysPermissionStatus() == .NotDetermined {
                LocationAlwaysAskPermission(callback)
            } else if LocationAlwaysPermissionStatus() == .Authorized {
                callback(RequestStatusCallback.AlreadyAuthorized)
            } else {
                callback(RequestStatusCallback.NeedSettings)
            }
            
        case .CoreLocationInUse:
            if LocationInUsePermissionStatus() == .NotDetermined {
                LocationInUseAskPermission(callback)
            } else if LocationInUsePermissionStatus() == .Authorized {
                callback(RequestStatusCallback.AlreadyAuthorized)
            } else {
                callback(RequestStatusCallback.NeedSettings)
            }
            
        default:
            callback(RequestStatusCallback.Denied)
        }
    }
    
    
    
    // MARK: - Permissions Methods
    
    private func AssetsLibraryPermissionStatus() -> StatusTypes {
        let status = ALAssetsLibrary.authorizationStatus()
        switch status {
        case .Authorized:
            return .Authorized
        case .Denied:
            return .Denied
        case .NotDetermined:
            return .NotDetermined
        case .Restricted:
            return .Restricted
        }
    }
    
    private func AssetsLibraryAskPermission(completion: ((RequestStatusCallback) -> ())) {
        var stop : UnsafeMutablePointer<Bool> = nil
        ALAssetsLibrary().enumerateGroupsWithTypes(ALAssetsGroupAll, usingBlock: { (group, stop) -> Void in
            if stop != nil {
                stop.memory = true
                completion(RequestStatusCallback.JustAuthorized)
            }
            }, failureBlock: { (error) -> Void in
                completion(RequestStatusCallback.Denied)
        })
    }
    
    
    private func CameraPermissionStatus() -> StatusTypes {
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        switch status {
        case .Authorized:
            return .Authorized
        case .Denied:
            return .Denied
        case .NotDetermined:
            return .NotDetermined
        case .Restricted:
            return .Restricted
        }
    }
    
    private func CameraAskPermission(completion: ((RequestStatusCallback) -> ())) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { (success) -> Void in
                if success {
                    completion(.JustAuthorized)
                } else {
                    completion(.Denied)
                }
            })
        })
    }
    
    
    private func CalendarPermissionStatus() -> StatusTypes {
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent)
        switch status {
        case .Authorized:
            return .Authorized
        case .Denied:
            return .Denied
        case .NotDetermined:
            return .NotDetermined
        case .Restricted:
            return .Restricted
        }
    }
    
    private func CalendarAskPermission(completion: ((RequestStatusCallback) -> ())) {
        EKEventStore().requestAccessToEntityType(EKEntityTypeEvent, completion: { (granted, error) -> Void in
            if granted {
                completion(.JustAuthorized)
            } else {
                completion(.Denied)
            }
        })
    }
    
    
    private func ContactsPermissionStatus() -> StatusTypes {
        let status = ABAddressBookGetAuthorizationStatus()
        switch status {
        case .Authorized:
            return .Authorized
        case .Denied:
            return .Denied
        case .NotDetermined:
            return .NotDetermined
        case .Restricted:
            return .Restricted
            
        }
    }
    
    
    private func ContactsAskPermission(completion: ((RequestStatusCallback) -> ())) {
        ABAddressBookRequestAccessWithCompletion(nil) { (granted, error) -> Void in
            if granted {
                completion(.JustAuthorized)
            } else {
                completion(.Denied)
            }
        }
    }
    
    
    private func MicrophonePermissionStatus() -> StatusTypes {
        let status = AVAudioSession.sharedInstance().recordPermission()
        switch status {
        case AVAudioSessionRecordPermission.Denied:
            return .Denied
        case AVAudioSessionRecordPermission.Undetermined:
            return .NotDetermined
        case AVAudioSessionRecordPermission.Granted:
            return .Authorized
        default:
            return .Restricted
        }
    }
    
    private func MicrophoneAskPermission(completion: ((RequestStatusCallback) -> ())) {
        AVAudioSession.sharedInstance().requestRecordPermission { (granted) -> Void in
            if granted {
                completion(.JustAuthorized)
            } else {
                completion(.Denied)
            }
        }
    }
    
    
    private func NotificationsPermissionStatus() -> StatusTypes {
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        if settings.types != UIUserNotificationType.None {
            return .Authorized
        } else {
            if NSUserDefaults.standardUserDefaults().boolForKey("PermissionScopeAskedForNotificationsDefaultsKey") {
                return .Denied
            } else {
                return .NotDetermined
            }
        }
    }
    
    private func NotificationsAskPermission(completion: ((RequestStatusCallback) -> ())) {
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
            let status = self.NotificationsPermissionStatus()
            if status == .Authorized {
                completion(.JustAuthorized)
            } else {
                completion(.Denied)
            }
        }
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "PermissionScopeAskedForNotificationsDefaultsKey")
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Sound | .Badge, categories: nil))
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    
    private func LocationAlwaysPermissionStatus() -> StatusTypes {
        if !CLLocationManager.locationServicesEnabled() {
            return .Denied
        }
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .AuthorizedAlways:
            return .Authorized
        case .Restricted, .Denied:
            return .Denied
        case .AuthorizedWhenInUse:
            if NSUserDefaults.standardUserDefaults().boolForKey("requestedInUseToAlwaysUpgrade") == true {
                return .Denied
            } else {
                return .NotDetermined
            }
        case .NotDetermined:
            return .NotDetermined
        }
    }
    
    private func LocationAlwaysAskPermission(completion: ((RequestStatusCallback) -> ())) {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "requestedInUseToAlwaysUpgrade")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        tempBlock = completion
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status != .Denied {
            tempBlock?(.JustAuthorized)
        } else {
            tempBlock?(.Denied)
        }
    }
    
    
    private func LocationInUsePermissionStatus() -> StatusTypes {
        if !CLLocationManager.locationServicesEnabled() {
            return .Denied
        }
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            return .Authorized
        case .Restricted, .Denied:
            return .Denied
        case .NotDetermined:
            return .NotDetermined
        }
    }
    
    private func LocationInUseAskPermission(completion: ((RequestStatusCallback) -> ())) {
        tempBlock = completion
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
    }
    
    
    
    
    
    
    
    
    
    
    
}
