//
//  MasterViewController.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/20/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController, CreationDateCategorizationViewModelDelegate {

  static let TodayRecordsTableSectionIndex = 0
  static let ThisWeekRecordsTableSectionIndex = 1
  static let ErlierRecordsTableSectionIndex = 2
  
  var detailViewController: DetailViewController? = nil
  var settingsViewController: SettingsViewController?
  var needToReloadData: Bool = false
  let tableViewProxy: CreationDateCategorizationViewModel =
      ViewModelsFactory.getCreationDateCategorizationViewModel(dataModel: DataModel.sharedInstance)
  
  @IBAction func unwindToContainerVC(segue: UIStoryboardSegue) {
    // This is called on unwidning from settings view controller to this view controller
    acceptApplicationSettingsChangeIfNecessary()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableViewProxy.delegate = self
    tableViewProxy.synchronizeWithExistingData()
    subscribeOnAppSettingsChanges()
    createSettingsButton()
    createNewRecordButton()
    setupUIAccordingToAppConfiguration()
  }
  
  func acceptApplicationSettingsChangeIfNecessary() {
    if needToReloadData {
      DiaryRecordViewFormatter.sharedInstance.loadConfigurationFromApplicationSettings()
      reloadTableData()
      needToReloadData = false
    }
  }
  
  func settingsChanged(note: NSNotification) {
    needToReloadData = true
  }
  
  func subscribeOnAppSettingsChanges() {
    NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("settingsChanged:"),
      name: "applicationSettingsChanged", object: nil)
  }
  
  func createSettingsButton() {
    let settingsButton = UIBarButtonItem(image: UIImage(named:"settings"), style: UIBarButtonItemStyle.Plain, target: self, action: "configureApp:")
    self.navigationItem.leftBarButtonItem = settingsButton
  }
  
  func createNewRecordButton() {
    let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
    self.navigationItem.rightBarButtonItem = addButton
    if let split = self.splitViewController {
      let controllers = split.viewControllers
      self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
    }
  }
  
  func configureApp(sender: AnyObject) {
    performSegueWithIdentifier("showSettings", sender: self)
  }
  
  override func viewWillAppear(animated: Bool) {
    self.clearsSelectionOnViewWillAppear = self.splitViewController!.collapsed
    super.viewWillAppear(animated)
    reloadTableData()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  func insertNewObject(sender: AnyObject) {
    DataModel.sharedInstance.addDiaryRecord(DiaryRecord())
    reloadTableData()
  }
  
  func reloadTableData() {
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
    }
  }
  
  // MARK: - SettingsControllerListner
  
  func settingsChanged() {
    setupUIAccordingToAppConfiguration()
    reloadTableData()
  }
  
  func setupUIAccordingToAppConfiguration() {
    DiaryRecordViewFormatter.sharedInstance.loadConfigurationFromApplicationSettings()
  }
  
  // MARK: - Table View BEGIN
  
  func getDataRecordForIndexPath(indexPath: NSIndexPath) -> DiaryRecord {
    return self.tableViewProxy.getDataRecordForIndexPath(indexPath)
  }
  
  func getDataRecordModelIdForIndexPath(indexPath: NSIndexPath) -> Int {
    return self.tableViewProxy.getDataRecordModelIdForIndexPath(indexPath)
  }

//  override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
//    let record = getDataRecordForIndexPath(indexPath)
//    let emptyRecordFixedHeight = CGFloat(50.0)
//    let nonEmptyRecordFixedHeight = CGFloat(100.0)
//    return record.text.isEmpty ? emptyRecordFixedHeight : nonEmptyRecordFixedHeight
//  }
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
     return self.tableViewProxy.getSectionsCount()
  }

  override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    return self.tableViewProxy.getSectionNameByIndex(section)
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.tableViewProxy.getSectionRowsCountBySection(section)
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
  
  override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      let recordId = getDataRecordModelIdForIndexPath(indexPath)
      DataModel.sharedInstance.removeDiaryRecordByID(recordId)
    } else if editingStyle == .Insert {
       // ..
    }
  }
  
  // MARK: - CreationDateCategorizationDataModelProxyDelegate methods

  func sectionCreated(sectionIndex: Int) -> Void {
    NSLog("sectionCreated(\(sectionIndex))")
  }
  
  func sectionDestroyed(sectionIndex: Int) -> Void {
    NSLog("sectionDestroyed(\(sectionIndex))")
  }

  func rowDeleted(section: Int, row: Int, lastRecord: Bool) -> Void {
    NSLog("rowDeleted(\(section), \(row))")
    if lastRecord {
      let indexset = NSIndexSet(index: section)
      self.tableView.deleteSections(indexset, withRowAnimation: .Fade)
    } else {
      let indexPath = NSIndexPath(forRow: row, inSection: section)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    }
  }
  
  func rowInserted(section: Int, row: Int) -> Void {
    NSLog("rowInserted(\(section), \(row))")
  }
  
  func rowUpdated(section: Int, row: Int) -> Void {
    NSLog("rowUpdated(\(section), \(row))")
  }
}

