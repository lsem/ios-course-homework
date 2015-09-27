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
  var objects = [DiaryRecord]()
  var settingsViewController: SettingsViewController?
  
  @IBAction func unwindToContainerVC(segue: UIStoryboardSegue) {
    // TODO: What should I do here?
    // Probably, this is right place for changing settings?
    NSLog("Unwind!")
  }
  
  func detailChanged(note: NSNotification) {
    // TODO: Consider possible optimisation is update only changed rows.
    self.refreshRecordTable()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    // Subscribe on notificaion from detail controller
    NSNotificationCenter.defaultCenter().addObserver(self, selector: "detailChanged:", name: "ChangeDetail", object: nil)
    
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
    setupUIAccordingToAppConfiguration()
  }
  
  func configureApp(sender: AnyObject) {
    performSegueWithIdentifier("showSettings", sender: self)
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
    objects.insert(DiaryRecord(), atIndex: 0)
    let indexPath = NSIndexPath(forRow: 0, inSection: 0)
    self.tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
  }
  
  func refreshRecordTable() {
    self.tableView.reloadData()
  }
  
  
  // MARK: - Segues
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showDetail" {
      if let indexPath = self.tableView.indexPathForSelectedRow {
        let selectedDiaryRecord = objects[indexPath.row]
        let controller = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
        controller.selectedDiaryRecord = selectedDiaryRecord
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
  
  func settingsChanged() {
    setupUIAccordingToAppConfiguration()
    refreshRecordTable()
  }
  
  func setupUIAccordingToAppConfiguration() {
    DiaryRecordViewFormatter.sharedInstance.loadConfigurationFromApplicationSettings()
  }
  
  // MARK: - Table View BEGIN

  // MARK: - UITableViewDataSource
  
  
  // MARK: - UITableViewDelegate

  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 50
  }
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 3
  }
  

  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0: return "Today"
    case 1: return "This Week"
    case 2: return "Eirlier"
    default:
      assert(false)
    }
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let today = NSDate()
    var flags = NSCalendarUnit()
    flags.insert(NSCalendarUnit.Day)
    flags.insert(NSCalendarUnit.WeekOfMonth)
    let todayComponents = NSCalendar.currentCalendar().components(flags, fromDate: today)

    var todayCount = 0
    var thisWeekCount = 0
//    var othersCount = 0
    
    
    
    // TODO: Cache this
    for o in self.objects {
      let objectDataComponents = NSCalendar.currentCalendar().components(flags, fromDate: o.creationDate)
      NSLog("objectDataComponents.day: \(objectDataComponents.day)")

      if objectDataComponents.day == todayComponents.day {
        todayCount += 1
      } else if objectDataComponents.weekOfYear == todayComponents.weekOfYear {
        thisWeekCount += 1
      }
    }
    
    
    if section == 0 {
      return todayCount
    } else if section == 1 {
      return thisWeekCount
    } else {
      return self.objects.count - thisWeekCount - todayCount
    }
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

    let selectedDiaryRecord = objects[indexPath.row]
//    
    NSLog("cellForRowAtIndexPath: \(indexPath.section):\(indexPath.row)")
//    
//    let today = NSDate()
//    var flags = NSCalendarUnit()
//    flags.insert(NSCalendarUnit.Day)
//    flags.insert(NSCalendarUnit.WeekOfMonth)
//    let todayComponents = NSCalendar.currentCalendar().components(flags, fromDate: today)
//    let cellComponents = NSCalendar.currentCalendar().components(flags, fromDate: selectedDiaryRecord.creationDate)
//    
//    if indexPath.section == 0 {
//      // Today section
//
//      //today
//      NSLog("section 0")
//      if cellComponents.day != todayComponents.day {
//        return UITableViewCell()
//      }
//    }
//
//    if indexPath.section == 1 {
//      // This Weak secion
//    }
//      
//    
//    
////    let selectedDiaryRecord = self.objects[indexPath.row]
    let (title, subtitle) = DiaryRecordViewFormatter.sharedInstance.recordMasterViewRow(selectedDiaryRecord)
    cell.textLabel!.text = title
    cell.detailTextLabel!.text = subtitle
    
    if cell is TableViewCell {
      let tableViewCell = cell as! TableViewCell
      switch selectedDiaryRecord.mood {
      case .Bad:
        tableViewCell.moodIconImage.image = UIImage(named: "rain_sm")
      case .Neutral:
        tableViewCell.moodIconImage.image = UIImage(named: "cloudy_sm")
      case .Good:
        tableViewCell.moodIconImage.image = UIImage(named: "sunny_sm")
      case .NoSet:
        tableViewCell.moodIconImage.image = nil
      }
    }
    
    return cell
  }
  
  // This would create all sorts of used queries
  func createReferenceCellsForGeometryQueries() {
    
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
  
    // MARK: - Table View END

}

