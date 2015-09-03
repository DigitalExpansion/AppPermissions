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
import CoreBluetooth
import Photos


let PermissionKeyNotifications = "AppPermissionsAskedNotifications"
let PermissionKeyBluetooth     = "AppPermissionsAskedBluetooth"
let PermissionKeyLocation      = "AppPermissionsUpgradedLocation"

class Permission: NSObject {
    let type : PermissionType
    let title : String
    
    init(type: PermissionType, title: String) {
        self.type = type
        self.title = title
        super.init()
    }
}


enum PermissionType : String {
    case AssetsLibrary  = "Camera Roll"
    case Bluetooth      = "Bluetooth"
    case Calendars      = "Calendars"
    case Camera         = "Camera"
    case Contacts       = "Contacts"
    case Events         = "Events"
    case LocationAlways = "Location Always"
    case LocationInUse  = "Location In Use"
    case Microphone     = "Microphone"
    case Notifications  = "Notifications"
    case Photos         = "Photos"     // iOS 8 (Photo Framework)
    case Reminders      = "Reminders"
    
    func imageName() -> String {
        var imgname = String(format: "ap_%@", self.rawValue)
        imgname = imgname.lowercaseString.stringByReplacingOccurrencesOfString(" ", withString: "_", options: .LiteralSearch, range: nil)
        return imgname
    }
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



class AppPermissions: NSObject, CLLocationManagerDelegate, CBPeripheralManagerDelegate {
    
    let lessThanEight = AppPermissionsViewController.lessThanEight()
    let locationManager: CLLocationManager
    var bluetoothManager: CBPeripheralManager?
    var completionBlock: ((RequestStatusCallback) -> ())?
    
    override init() {   
        self.locationManager = CLLocationManager()
        super.init()
    }
    
    func status(forType type: PermissionType) -> StatusType {
        switch type {
        case .AssetsLibrary:  return statusForAssetsLibrary()
        case .Bluetooth:      return statusForBluetooth()
        case .Calendars:      return statusForCalendar()
        case .Camera:         return statusForCamera()
        case .Contacts:       return statusForContacts()
        case .Events:         return statusForEvents()
        case .LocationAlways: return statusForLocationAlways()
        case .LocationInUse:  return statusForLocationInUse()
        case .Microphone:     return statusForMicrophone()
        case .Notifications:  return statusForNotifications()
        case .Photos:         return statusForPhoto()
        case .Reminders:      return statusForReminders()
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
        case .Bluetooth:      askBluetoth(callback)
        case .Calendars:      askCalendar(callback)
        case .Camera:         askCamera(callback)
        case .Contacts:       askContacts(callback)
        case .Events:         askEvents(callback)
        case .LocationAlways: askLocationAlways(callback)
        case .LocationInUse:  askLocationInUse(callback)
        case .Microphone:     askMicrophone(callback)
        case .Notifications:  askNotifications(callback)
        case .Photos:         askPhoto(callback)
        case .Reminders:      askReminders(callback)
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
        return (lessThanEight) ? statusForMicrophone7() : statusForMicrophone8()
    }
    
    private func statusForMicrophone7() -> StatusType {
        switch AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeAudio) {
        case .Authorized:          return .Authorized
        case .Restricted, .Denied: return .Denied
        case .NotDetermined:       return .NotDetermined
        }
    }
    
    private func statusForMicrophone8() -> StatusType {
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
#if __IPHONE_8_0
        return statusForNotifications8()
#else
        return statusForNotifications7()
#endif
    }
    
    private func statusForNotifications7() -> StatusType {
#if __IPHONE_8_0
        return .Denied
#else
        let settings = UIApplication.sharedApplication().enabledRemoteNotificationTypes()
        if settings == UIRemoteNotificationType.None {
            if NSUserDefaults.standardUserDefaults().boolForKey(PermissionKeyNotifications) { return .Denied } else { return .NotDetermined }
        }
        return .Authorized
#endif
    }
    
    private func statusForNotifications8() -> StatusType {
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        if settings.types == UIUserNotificationType.None {
            if NSUserDefaults.standardUserDefaults().boolForKey(PermissionKeyNotifications) { return .Denied } else { return .NotDetermined }
        }
        return .Authorized
    }
    
    private func askNotifications(completion: ((RequestStatusCallback) -> ())) {
        NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidBecomeActiveNotification, object: nil, queue: NSOperationQueue.mainQueue()) { notification in
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
            let status: RequestStatusCallback = (self.statusForNotifications() == .Authorized) ? .JustAuthorized : .Denied
            completion(status)
        }
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: PermissionKeyNotifications)
        NSUserDefaults.standardUserDefaults().synchronize()
#if __IPHONE_8_0
            let types = UIRemoteNotificationType.Badge | UIRemoteNotificationType.Sound | UIRemoteNotificationType.Alert
            UIApplication.sharedApplication().registerForRemoteNotificationTypes(types)
#else
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Sound | .Badge, categories: nil))
            UIApplication.sharedApplication().registerForRemoteNotifications()
#endif
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
            if NSUserDefaults.standardUserDefaults().boolForKey(PermissionKeyLocation) {
                return .Denied
            } else {
                return .NotDetermined
            }
        }
    }
    
    
    private func askLocationAlways(completion: ((RequestStatusCallback) -> ())) {
        return lessThanEight ? askLocationAlways7(completion) : askLocationAlways8(completion)
    }
    
    private func askLocationAlways7(completion: ((RequestStatusCallback) -> ())) {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: PermissionKeyLocation)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        completionBlock = completion
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    private func askLocationAlways8(completion: ((RequestStatusCallback) -> ())) {
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: PermissionKeyLocation)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        completionBlock = completion
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
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
        return lessThanEight ? askLocationInUse7(completion) : askLocationInUse8(completion)
    }
    
    private func askLocationInUse7(completion: ((RequestStatusCallback) -> ())) {
        completionBlock = completion
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
        
    }
    private func askLocationInUse8(completion: ((RequestStatusCallback) -> ())) {
        completionBlock = completion
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    
    private func statusForBluetooth() -> StatusType {
        if NSUserDefaults.standardUserDefaults().boolForKey(PermissionKeyBluetooth)  {
            if bluetoothManager == nil {
                bluetoothManager = CBPeripheralManager(delegate: nil, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
            }
            switch CBPeripheralManager.authorizationStatus() {
            case .Authorized: return .Authorized
            case .Denied:     return .Denied
            default:          break
            }
        }
        return .NotDetermined
    }
    
    private func askBluetoth(completion: ((RequestStatusCallback) -> ())) {
        completionBlock = completion
        bluetoothManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
        CBPeripheralManager.authorizationStatus()
    }
    
    
    private func statusForPhoto() -> StatusType {
        if self.lessThanEight {
            return .Authorized
        }
        switch PHPhotoLibrary.authorizationStatus() {
        case .Authorized:          return .Authorized
        case .Denied, .Restricted: return .Denied
        case .NotDetermined:       return .NotDetermined
        }
    }
    
    private func askPhoto(completion: ((RequestStatusCallback) -> ())) {
        PHPhotoLibrary.requestAuthorization { status in
            status == .Authorized ? completion(.JustAuthorized) : completion(.Denied)
        }
    }
    
    
    private func statusForReminders() -> StatusType {
        switch EKEventStore.authorizationStatusForEntityType(EKEntityTypeReminder) {
        case .Authorized:          return .Authorized
        case .Denied, .Restricted: return .Denied
        case .NotDetermined:       return .NotDetermined
        }
    }
    
    private func askReminders(completion: ((RequestStatusCallback) -> ())) {
        EKEventStore().requestAccessToEntityType(EKEntityTypeReminder, completion: { granted, error in
            granted ? completion(.JustAuthorized) : completion(.Denied)
        })
    }
    
    
    private func statusForEvents() -> StatusType {
        switch EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent) {
        case .Authorized:          return .Authorized
        case .Denied, .Restricted: return .Denied
        case .NotDetermined:       return .NotDetermined
        }
    }
    
    private func askEvents(completion: ((RequestStatusCallback) -> ())) {
        EKEventStore().requestAccessToEntityType(EKEntityTypeEvent, completion: { granted, error in
            granted ? completion(.JustAuthorized) : completion(.Denied)
        })
    }
    
    
    
    // MARK: - CBPeripheralManagerDelegate
    
    func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: PermissionKeyBluetooth)
        NSUserDefaults.standardUserDefaults().synchronize()
        if CBPeripheralManager.authorizationStatus() == .Authorized {
            completionBlock?(.JustAuthorized)
        } else {
            completionBlock?(.Denied)
        }
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
