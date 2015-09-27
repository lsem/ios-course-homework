//
//  MasterViewController.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/20/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, SettingsControllerListener {

  static let TodayRecordsTableSectionIndex = 0
  static let ThisWeekRecordsTableSectionIndex = 1
  static let ErlierRecordsTableSectionIndex = 1
  
  var detailViewController: DetailViewController? = nil
  var settingsViewController: SettingsViewController?
  let dataModelProxy: DataModelUIProxy = DataModelUIProxy(dataModel: DataModel.sharedInstance)
  
  @IBAction func unwindToContainerVC(segue: UIStoryboardSegue) {
    // TODO: What should I do here?
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
    refreshRecordTable()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func insertNewObject(sender: AnyObject) {
    DataModel.sharedInstance.addDiaryRecord(DiaryRecord())
    refreshRecordTable()
  }
  
  func refreshRecordTable() {
    self.tableView.reloadData()
  }
  
  
  // MARK: - Segues
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "showDetail" {
      if let indexPath = self.tableView.indexPathForSelectedRow {
        let recordModelId = getDataRecordModelIdForIndexPath(indexPath)
        let detailController = (segue.destinationViewController as! UINavigationController).topViewController as! DetailViewController
        detailController.recordModelId = recordModelId
        detailController.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
        detailController.navigationItem.leftItemsSupplementBackButton = true
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
  
  enum RecordsCategory { case Today; case ThisWeek; case Erlier }
  
  func decodeRecordCategoryForSection(section: Int) -> RecordsCategory {
    let todayRecordsCount = self.dataModelProxy.todayRecordsCount
    let thisWeekRecordsCount = self.dataModelProxy.thisWeekRecordsCount
    let erlierRecordsCount = self.dataModelProxy.erlierRecordsCount
    switch section  {
    case MasterViewController.TodayRecordsTableSectionIndex:
      if todayRecordsCount > 0 { return .Today }
      if thisWeekRecordsCount > 0 { return .ThisWeek }
      if erlierRecordsCount > 0 { return .Erlier }
      assert(false)
    case MasterViewController.ThisWeekRecordsTableSectionIndex:
      if todayRecordsCount > 0 {
        if thisWeekRecordsCount > 0 {
          return .ThisWeek
        } else {
          return .Erlier
        }
      } else {
        // no today records
        assert(erlierRecordsCount > 0)
        return .Erlier
      }
    case MasterViewController.ErlierRecordsTableSectionIndex:
      assert(erlierRecordsCount > 0)
      return .Erlier
    default:
      assert(false)
    }
  }
  
  func getDataRecordForIndexPath(indexPath: NSIndexPath) -> DiaryRecord {
    let category = decodeRecordCategoryForSection(indexPath.section)
    switch category {
    case .Today: return self.dataModelProxy.getTodayRecordAtIndex(indexPath.row)
    case .ThisWeek: return self.dataModelProxy.getThisWeelRecordAtIndex(indexPath.row)
    case .Erlier: return self.dataModelProxy.getErlierRecordAtIndex(indexPath.row)
    }
  }
  
  func getDataRecordModelIdForIndexPath(indexPath: NSIndexPath) -> Int {
    let category = decodeRecordCategoryForSection(indexPath.section)
    switch category {
    case .Today: return self.dataModelProxy.getModelRecordIdByTodayRecordIndex(indexPath.row)
    case .ThisWeek: return self.dataModelProxy.getModelRecordIdByThisWeekRecordIndex(indexPath.row)
    case .Erlier: return self.dataModelProxy.getModelRecordIdByErlierRecordIndex(indexPath.row)
    }
  }

//  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//    let record = getDataRecordForIndexPath(indexPath)
//    let emptyRecordFixedHeight = CGFloat(50.0)
//    let nonEmptyRecordFixedHeight = CGFloat(100.0)
//    return record.text.isEmpty ? emptyRecordFixedHeight : nonEmptyRecordFixedHeight
//  }
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    var sectionsCount = 0
    if self.dataModelProxy.todayRecordsCount > 0 { sectionsCount += 1 }
    if self.dataModelProxy.thisWeekRecordsCount > 0 { sectionsCount += 1 }
    if self.dataModelProxy.erlierRecordsCount > 0 { sectionsCount += 1 }
    return sectionsCount
  }

  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    let category = decodeRecordCategoryForSection(section)
    switch category {
    case .Today: return "Today"
    case .ThisWeek: return "This Week"
    case .Erlier: return "Erlier"
    }
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let category = decodeRecordCategoryForSection(section)
    switch category {
    case .Today:
      return self.dataModelProxy.todayRecordsCount
    case .ThisWeek:
      return self.dataModelProxy.thisWeekRecordsCount
    case .Erlier:
      return self.dataModelProxy.erlierRecordsCount
    }
  }
  
  func prepareCell(cell: UITableViewCell, forRecord record: DiaryRecord) -> UITableViewCell {
    let (title, subtitle) = DiaryRecordViewFormatter.sharedInstance.recordMasterViewRow(record)
    cell.textLabel!.text = title
    cell.detailTextLabel!.text = subtitle
    if cell is TableViewCell {
      let tableViewCell = cell as! TableViewCell
      switch record.mood {
      case .Bad: tableViewCell.moodIconImage.image = UIImage(named: "rain_sm")
      case .Neutral: tableViewCell.moodIconImage.image = UIImage(named: "cloudy_sm")
      case .Good: tableViewCell.moodIconImage.image = UIImage(named: "sunny_sm")
      case .NoSet: tableViewCell.moodIconImage.image = nil
      }
    }
    return cell
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    let record = getDataRecordForIndexPath(indexPath)
    return prepareCell(cell, forRecord: record)
  }
  
  override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return false if you do not want the specified item to be editable.
    return true
  }
  
  func isSectionAboutToBeEmpty(section: Int) -> Bool {
    let category = decodeRecordCategoryForSection(section)
    switch category {
    case .Today: return self.dataModelProxy.todayRecordsCount == 1
    case .ThisWeek: return self.dataModelProxy.thisWeekRecordsCount == 1
    case .Erlier: return self.dataModelProxy.erlierRecordsCount == 1
    }
  }
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      // This is disgusting..
      let recordId = getDataRecordModelIdForIndexPath(indexPath)
      if isSectionAboutToBeEmpty(indexPath.section) {
        DataModel.sharedInstance.removeDiaryRecordAt(index: recordId)
        let indexset = NSIndexSet(index: indexPath.section)
        tableView.deleteSections(indexset, withRowAnimation: .Fade)
      } else {
        DataModel.sharedInstance.removeDiaryRecordAt(index: recordId)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
      }
    } else if editingStyle == .Insert {
      // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
  }
}

