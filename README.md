# AppPermissions
[![Language](http://img.shields.io/badge/language-swift-brightgreen.svg?style=flat)]
(https://developer.apple.com/swift)
[![Cocoapods compatible](https://cocoapod-badges.herokuapp.com/v/PermissionScope/badge.png)]
(https://cocoapods.org/pods/AppPermissions)

## installation

iOS 8:
`pod 'PermissionScope', '~> 0.7'`

iOS 7:
from Source Files

##  usage

### preconfiguration

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
### present permissions controller

```swift
AppPermissionsViewController.present(self, types: [.Calendars, .Camera, .Contacts]) { success in
        if success {
            ...
        }
```

### available permissions
