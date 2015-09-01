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
    let type : PermissionType
    let title : String
    var button: UIButton?
    var imageView: UIImageView?
    
    init(type: PermissionType, title: String) {
        self.type = type
        self.title = title
        super.init()
    }
}


enum PermissionType : String {
    case AssetsLibrary  = "Camera Roll"
    case Camera         = "Camera"
    case Calendars      = "Calendars"
    case Contacts       = "Contacts"
    case LocationAlways = "Location Always"
    case LocationInUse  = "Location In Use"
    case Microphone     = "Microphone"
    case Notifications  = "Notifications"
    case Reminders      = "Reminders"
    case Photos         = "Photos"     // iOS 8 (Photo Framework)
}


enum StatusType {
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
    var completionBlock: ((RequestStatusCallback) -> ())?
    
    init(useLocation: Bool = false) {
        super.init()
        if useLocation {
            locationManager = CLLocationManager()
        }
    }
    
    
    func status(forType type: PermissionType) -> StatusType {
        switch type {
        case .AssetsLibrary:  return statusForAssetsLibrary()
        case .Camera:         return statusForCamera()
        case .Calendars:      return statusForCalendar()
        case .Contacts:       return statusForContacts()
        case .Microphone:     return statusForMicrophone()
        case .Notifications:  return statusForNotifications()
        case .LocationAlways: return statusForLocationAlways()
        case .LocationInUse:  return statusForLocationInUse()
        default:
            return .NotDetermined
        }
    }
    
    
    func isAuthorized(permissions: [Permission]) -> Bool {
        for permission in permissions {
            if self.status(forType: permission.type) != .Authorized {
                return false
            }
        }
        return true
    }
    
    
    func ask(forType type: PermissionType, callback: ((RequestStatusCallback) -> ())) {
        let status: StatusType = self.status(forType: type)
        
        if status == .Authorized {
            callback(RequestStatusCallback.AlreadyAuthorized)
            return
        }
        if status == .Denied || status == .Restricted {
            callback(RequestStatusCallback.NeedSettings)
            return
        }
        
        // if status == .NotDetermined
        switch type {
        case .AssetsLibrary:  askAssetsLibrary(callback)
        case .Camera:         askCamera(callback)
        case .Calendars:      askCalendar(callback)
        case .Contacts:       askContacts(callback)
        case .Microphone:     askMicrophone(callback)
        case .Notifications:  askNotifications(callback)
        case .LocationAlways: askLocationAlways(callback)
        case .LocationInUse:  askLocationInUse(callback)
        default:
            callback(RequestStatusCallback.Denied)
        }
    }
    
    
    
    // MARK: - Permissions Methods
    
    private func statusForAssetsLibrary() -> StatusType {
        switch ALAssetsLibrary.authorizationStatus() {
        case .Authorized:    return .Authorized
        case .Denied:        return .Denied
        case .NotDetermined: return .NotDetermined
        case .Restricted:    return .Restricted
        }
    }
    
    private func askAssetsLibrary(completion: ((RequestStatusCallback) -> ())) {
        var stop : UnsafeMutablePointer<Bool> = nil
        ALAssetsLibrary().enumerateGroupsWithTypes(ALAssetsGroupAll,
            usingBlock: { group, stop in
                if stop != nil {
                    stop.memory = true
                    completion(RequestStatusCallback.JustAuthorized)
                }
            }, failureBlock: { error in
                completion(RequestStatusCallback.Denied)
        })
    }
    
    
    private func statusForCamera() -> StatusType {
        switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo) {
        case .Authorized:    return .Authorized
        case .Denied:        return .Denied
        case .NotDetermined: return .NotDetermined
        case .Restricted:    return .Restricted
        }
    }
    
    private func askCamera(completion: ((RequestStatusCallback) -> ())) {
        dispatch_async(dispatch_get_main_queue(), {
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo, completionHandler: { success in
                let status: RequestStatusCallback = success ? .JustAuthorized : .Denied
                completion(status)
            })
        })
    }
    
    
    private func statusForCalendar() -> StatusType {
        switch EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent) {
        case .Authorized:    return .Authorized
        case .Denied:        return .Denied
        case .NotDetermined: return .NotDetermined
        case .Restricted:    return .Restricted
        }
    }
    
    private func askCalendar(completion: ((RequestStatusCallback) -> ())) {
        EKEventStore().requestAccessToEntityType(EKEntityTypeEvent, completion: { granted, error in
            let status: RequestStatusCallback = granted ? .JustAuthorized : .Denied
            completion(status)
        })
    }
    
    
    private func statusForContacts() -> StatusType {
        switch ABAddressBookGetAuthorizationStatus() {
        case .Authorized:    return .Authorized
        case .Denied:        return .Denied
        case .NotDetermined: return .NotDetermined
        case .Restricted:    return .Restricted
        }
    }
    
    
    private func askContacts(completion: ((RequestStatusCallback) -> ())) {
        ABAddressBookRequestAccessWithCompletion(nil) { granted, error in
            let status: RequestStatusCallback = granted ? .JustAuthorized : .Denied
            completion(status)
        }
    }
    
    
    private func statusForMicrophone() -> StatusType {
        switch AVAudioSession.sharedInstance().recordPermission() {
        case AVAudioSessionRecordPermission.Denied:       return .Denied
        case AVAudioSessionRecordPermission.Undetermined: return .NotDetermined
        case AVAudioSessionRecordPermission.Granted:      return .Authorized
        default: return .Restricted
        }
    }
    
    private func askMicrophone(completion: ((RequestStatusCallback) -> ())) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            let status: RequestStatusCallback = granted ? .JustAuthorized : .Denied
            completion(status)
        }
    }
    
    
    private func statusForNotifications() -> StatusType {
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
    
    private func askNotifications(completion: ((RequestStatusCallback) -> ())) {
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: NSOperationQueue.mainQueue()) { notification in
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
            let status: RequestStatusCallback = (self.statusForNotifications() == .Authorized) ? .JustAuthorized : .Denied
            completion(status)
        }
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "PermissionScopeAskedForNotificationsDefaultsKey")
        UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Sound | .Badge, categories: nil))
        UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    
    private func statusForLocationAlways() -> StatusType {
        if !CLLocationManager.locationServicesEnabled() {
            return .Denied
        }
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways: return .Authorized
        case .Restricted:       return .Denied
        case .Denied:           return .Denied
        case .NotDetermined:    return .NotDetermined
        case .AuthorizedWhenInUse:
            if NSUserDefaults.standardUserDefaults().boolForKey("requestedInUseToAlwaysUpgrade") == true {
                return .Denied
            } else {
                return .NotDetermined
            }
        }
    }
    
    private func askLocationAlways(completion: ((RequestStatusCallback) -> ())) {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "requestedInUseToAlwaysUpgrade")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        completionBlock = completion
        locationManager?.delegate = self
        locationManager?.requestAlwaysAuthorization()
    }
    
    private func statusForLocationInUse() -> StatusType {
        if !CLLocationManager.locationServicesEnabled() {
            return .Denied
        }
        switch CLLocationManager.authorizationStatus() {
        case .AuthorizedAlways, .AuthorizedWhenInUse: return .Authorized
        case .Restricted, .Denied:                    return .Denied
        case .NotDetermined:                          return .NotDetermined
        }
    }
    
    private func askLocationInUse(completion: ((RequestStatusCallback) -> ())) {
        completionBlock = completion
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
    }
    
    
    // MARK: CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status != .Denied {
            completionBlock?(.JustAuthorized)
        } else {
            completionBlock?(.Denied)
        }
    }
    
}
