//
//  MasterViewController.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/20/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, SettingsControllerListener {
  
  var detailViewController: DetailViewController? = nil
  var objects = [AnyObject]()
  var settingsViewController: SettingsViewController?
  
  @IBAction func unwindToContainerVC(segue: UIStoryboardSegue) {
    NSLog("Unwind!")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    // Create settings button and attach to navigation controller
    let settingsButton = UIBarButtonItem(image: UIImage(named:"settings"), style: UIBarButtonItemStyle.Plain, target: self, action: "configureApp:")
    self.navigationItem.leftBarButtonItem = settingsButton
    
    // Create add button
    let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
    self.navigationItem.rightBarButtonItem = addButton
    if let split = self.splitViewController {
      let controllers = split.viewControllers
      self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
    }
  }
  
  func configureApp(sender: AnyObject) {
    NSLog("Settings requrested; performing segaue")
    performSegueWithIdentifier("showSettings", sender: self)
    NSLog("segauge requested")
  }
  
  override func viewWillAppear(animated: Bool) {
    self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
    super.viewWillAppear(animated)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func insertNewObject(sender: AnyObject) {
    NSLog("insert pressed");
    objects.insert(NSDate(), atIndex: 0)
    let indexPath = NSIndexPath(forRow: 0, inSection: 0)
    self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
  }
  
  // MARK: - Segues
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
      NSLog("Navigation to segue \(segue.identifier)!!!")
    if segue.identifier == "showDetail" {
      if let indexPath = self.tableView.indexPathForSelectedRow {
        let object = objects[indexPath.row] as! NSDate
        let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
        controller.detailItem = object
        controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
        controller.navigationItem.leftItemsSupplementBackButton = true
      }
    } else if segue.identifier == "showSettings" {
      let settingsNavigationController = (segue.destinationViewController as! UINavigationController).topViewController
      self.settingsViewController = settingsNavigationController as? SettingsViewController
      self.settingsViewController?.settingsControllerListener = self
    }
  }
  
  // MARK: - SettingsControllerListner
  func naturalLanguageSupportConfigured(enabled: Bool) {
    NSLog("Master: Natural language support configured: \(enabled)")
  }
  func dateTimeFormatChanged(format: DateTimeViewFormat) {
    NSLog("Master: DateTime format changed: \(format)")
  }
  
  
  // MARK: - Table View
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return objects.count
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    
    let object = objects[indexPath.row] as! NSDate
    cell.textLabel!.text = object.description
    return cell
  }
  
  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the specified item to be editable.
    return true
  }
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      objects.removeAtIndex(indexPath.row)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
      // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
  }

}

