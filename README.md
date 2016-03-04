# AppPermissions
[![Language](http://img.shields.io/badge/language-swift-brightgreen.svg?style=flat)]
(https://developer.apple.com/swift)
[![CocoaPods compatible](http://img.shields.io/cocoapods/v/AppPermissions.svg?style=flat)]
(https://cocoapods.org/pods/AppPermissions)

## Installation

iOS 8:
`pod 'AppPermissions'`

iOS 7:
from Source Files

### Preconfiguration

in `applicationDidBecomeActive`  in `AppDelegate` add:

```swift
func applicationDidBecomeActive(application: UIApplication) {
        
        if let root = self.window?.rootViewController {
            AppPermissionsViewController.restoreControllerIfNeeded(root)
        }
    }
```

if iOS 7 add:
```swift
func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        ...
        
        self.window?.rootViewController?.modalPresentationStyle = UIModalPresentationStyle.CurrentContext;
        return true
    }
```
### Present permissions controller

```swift
AppPermissionsViewController.present(self, types: [.Calendars, .Camera, .Contacts]) { success in
        if success {
            ...
        }
```

### Available permissions 
* PermissionType.AssetsLibrary
* .Bluetooth
* .Calendars
* .Camera
* .Contacts
* .Events
* .LocationAlways
* .LocationInUse
* .Microphone
* .Notifications
* .Photos
* .Reminders

#### About Location Permission

add in `info.plist` rows `NSLocationAlwaysUsageDescription` and `NSLocationWhenInUseUsageDescription` for description in dialog message (required)

#### About Bluetooth Permission

add in `info.plist` row `NSBluetoothPeripheralUsageDescription` and enable `background-modes` in the `capabilities` section and check the `Acts as a Bluetooth LE accessory` checkbox (required)
