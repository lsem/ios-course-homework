//
//  AppDelegate.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/20/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
  
  var window: UIWindow?
  var masterViewController: MasterViewController?
  let repository = SystemKeyArchiverUnarchiverRepository()
  
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
    loadApplicationConfiguration()
    loadDataIfThereAreAny()
    becomeDetailViewControllerDelegate()
    resolveMasterViewController()
    return true
  }
  
  func loadApplicationConfiguration() {
    let instance = ApplicationSettings.sharedInstance
    if !instance.loadFromLocalFileSystemStorage() {
      instance.loadFactorySettings()
    }
  }
  
  func resolveMasterViewController() {
    let splitViewController = self.window!.rootViewController as! UISplitViewController
    let masterNavigationController = splitViewController.viewControllers[0] as! UINavigationController
    self.masterViewController = masterNavigationController.viewControllers[0] as? MasterViewController
  }
  
  func becomeDetailViewControllerDelegate() {
    let splitViewController = self.window!.rootViewController as! UISplitViewController
    let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
    navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
    splitViewController.delegate = self
  }
  
  func applicationWillResignActive(application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
  }
  
  func applicationDidEnterBackground(application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    storeDataIfNecessary()
  }
  
  func applicationWillEnterForeground(application: UIApplication) {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
  }
  
  func applicationDidBecomeActive(application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
  }
  
  func applicationWillTerminate(application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    storeDataIfNecessary()
  }
  
  func storeDataIfNecessary() {
    let allDiaryRecords = DataModel.sharedInstance.retrieveAllDiaryRecords()
    let allDiaryRecordsArray = Array<DiaryRecord>(allDiaryRecords.values)
    self.repository.storeDiaryRecordCollection(allDiaryRecordsArray)
  }
  
  func loadDataIfThereAreAny() {
    if let loadedData = self.repository.loadDiaryRecordCollection() {
      let dataModel = DataModel.sharedInstance
      dataModel.initFromArray(loadedData)
    } else {
      // It could be either due to failed initialization or because of first run.
      // Lets initialize with some hard coded.
      // Alternativey, we could ask repository to get seed data, but this is out of scope for this MVP.
      let initialData = [
        DiaryRecord(name: "Finally", text: "Finally I almost done first home work..", mood: RecordMood.Good),
        DiaryRecord(name: "Things getting better", text: "Trying to implement persistance", mood: RecordMood.Neutral),
      ]
      DataModel.sharedInstance.initFromArray(initialData)
    }
  }
  
  // MARK: - Split view
  
  func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController:UIViewController, ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
    guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
    guard let topAsDetailController = secondaryAsNavController.topViewController as? DetailViewController else { return false }
    if topAsDetailController.detailItem == nil {
      // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
      return true
    }
    return false
  }
  
}

