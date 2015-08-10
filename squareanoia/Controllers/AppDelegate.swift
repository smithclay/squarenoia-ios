//
//  AppDelegate.swift
//  squareanoia
//
//  Created by Clay Smith  on 6/22/15
//  Copyright (c) 2015 . All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {

        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Sound | UIUserNotificationType.Alert | UIUserNotificationType.Badge, categories: nil))

        return true
    }

    func application(application: UIApplication, handleWatchKitExtensionRequest userInfo: [NSObject : AnyObject]?, reply: (([NSObject : AnyObject]!) -> Void)!) {
        var replyDictionary = [NSObject: AnyObject]()
        replyDictionary["count"] = DataModel.sharedInstance.nearbyViolentCrimeCount(DataModel.sharedInstance.lastKnownLocation)
        replyDictionary["lat"] =  DataModel.sharedInstance.lastKnownLocation?.coordinate.latitude
        replyDictionary["long"] =  DataModel.sharedInstance.lastKnownLocation?.coordinate.longitude
        reply(replyDictionary)
    }
}
