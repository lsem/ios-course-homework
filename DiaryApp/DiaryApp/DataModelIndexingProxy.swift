//
//  DataModelIndexingProxy.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/30/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit

protocol DataModelIndexingProxyDelegate : class {
  func recordAdded(id: RecordID) -> Void
  func recordUpdated(id: RecordID) -> Void
  func recordRemoved(id: RecordID) -> Void
}

// This somewhat poorly designed class responsible for indexing data 
// which are stored in DataModel class. This indices should not be used directly, but via dedicated ViewModel classes
// (e.g: CreationDateCategorizationViewModel). It would be nice to have indices:
//  1) separated
//  2) Have generalized date class in creation date categorization index instead of hardcoded and copypasted 
//      thisWeek, today, erlier, etc.. 3)
//  3) More error handling and fool-resistant.
// Anyway it at least correct. 

class DataModelIndexingProxy : DataModelDelegate {
  private var dataModel: DataModel
  private var creationDataIndex: Array<Int>
  private var todayRecordsIndex: Array<Int>
  private var thisWeekRecordsIndex: Array<Int>
  private var erlierRecordsIndex: Array<Int>
  private var dateOrderedIndexData: Array<Int>
  private var moodOrderedIndexData: Dictionary<RecordMood, Array<Int>>
  private var cacheValid: Bool
  private var moodCacheValid: Bool
  weak var delegate: DataModelIndexingProxyDelegate?
  
  private lazy var dateComponentsRetrievalFlags: NSCalendarUnit = {
    var flags = NSCalendarUnit()
    flags.insert(NSCalendarUnit.Day)
    flags.insert(NSCalendarUnit.WeekOfMonth)
    flags.insert(NSCalendarUnit.Month)
    flags.insert(NSCalendarUnit.Year)
    flags.insert(NSCalendarUnit.WeekOfYear)
    return flags
    }()
  
  init(dataModel: DataModel) {
    self.dataModel = dataModel
    self.creationDataIndex = []
    self.todayRecordsIndex = []
    self.thisWeekRecordsIndex = []
    self.erlierRecordsIndex = []
    self.dateOrderedIndexData = []
    self.moodOrderedIndexData = [ .NoSet: [], .Neutral: [], .Good: [], RecordMood.Bad: [] ]
    self.cacheValid = false
    self.moodCacheValid = false
    self.dataModel.delegate = self
    self.delegate = nil
  }
  
  // MARK: - Public methods and properties
  
  func synchronizeWithExistingData() {
    let allData = self.dataModel.retrieveAllDiaryRecords()
    for (recordId, _/*record*/) in allData {
      notifyRecordAdded(recordId)
    }
  }
  
  var todayRecordsCount: Int { get {
    rebuildDateRecordsCacheIfNecessary()
    return self.todayRecordsIndex.count
    }
  }
  
  func getTodayRecordAtIndex(index: Int) -> DiaryRecord! {
    let recordID = getModelRecordIdByTodayRecordIndex(index)
    let reocord = self.dataModel.retrieveDiaryRecordByID(recordID)
    return reocord
  }
  
  func retrieveTodayRecords() -> [(RecordID, DiaryRecord)] {
    rebuildDateRecordsCacheIfNecessary()
    // TODO: Reserve memory for ahead
    var todayRecords: Array<(RecordID, DiaryRecord)> = []
    for recordId in self.todayRecordsIndex {
      if let record = self.dataModel.retrieveDiaryRecordByID(recordId) {
        todayRecords.append((recordId,record))
      } else {
        assert(false, "Inconsistency in index")
      }
    }
    return todayRecords
  }
  
  var thisWeekRecordsCount: Int { get {
    rebuildDateRecordsCacheIfNecessary()
    return self.thisWeekRecordsIndex.count
    }
  }
  
  func getThisWeelRecordAtIndex(index: Int) -> DiaryRecord {
    let recordID = getModelRecordIdByThisWeekRecordIndex(index)
    let record = self.dataModel.retrieveDiaryRecordByID(recordID)
    assert(record != nil, "Inconsistency of Index")
    return record!
  }
  
  func retrieveTheseWeekRecords() -> [(RecordID, DiaryRecord)] {
    rebuildDateRecordsCacheIfNecessary()
    // TODO: Reserve memory for ahead
    var weekRecords: Array<(RecordID, DiaryRecord)> = []
    for recordId in self.thisWeekRecordsIndex {
      let record = self.dataModel.retrieveDiaryRecordByID(recordId)
      assert(record != nil, "Inconsistency of Index")
      weekRecords.append((recordId,record!))
    }
    return weekRecords
  }
  
  var erlierRecordsCount: Int { get {
    rebuildDateRecordsCacheIfNecessary()
    return self.erlierRecordsIndex.count
    }
  }
  
  func getErlierRecordAtIndex(index: Int) -> DiaryRecord {
    let recordID = getModelRecordIdByErlierRecordIndex(index)
    let record = self.dataModel.retrieveDiaryRecordByID(recordID)
    assert(record != nil, "Inconsistency in Index")
    return record!
  }
  
  func retrieveErlierRecords() -> [(RecordID, DiaryRecord)] {
    rebuildDateRecordsCacheIfNecessary()
    // TODO: Reserve memory for ahead
    var erlierRecords: Array<(RecordID, DiaryRecord)> = []
    for recordId in self.erlierRecordsIndex {
      let record = self.dataModel.retrieveDiaryRecordByID(recordId)
      assert(record != nil, "Inconsistency of Index")
      erlierRecords.append((recordId, record!))
    }
    return erlierRecords
  }
  
  // Mood ordered index accessors
  func getRecordsCountForMood(mood: RecordMood) -> Int {
    rebuildDateRecordsCacheIfNecessary()
    if let indexForMood = self.moodOrderedIndexData[mood] {
      return indexForMood.count
    }
    assert(false)
  }
  
  func getMoodRecordAtIndexForMood(mood: RecordMood, index: Int) -> DiaryRecord {
    let recordID = getModelRecordByMoodOrderedIndex(mood, index: index)
    let record = self.dataModel.retrieveDiaryRecordByID(recordID)
    assert(record != nil, "Inconsistency of Index")
    return record!
  }
  
  func retrieveAllRecordsSortedByCreationDate() -> [DiaryRecord] {
    rebuildDateRecordsCacheIfNecessary()
    var sortedRecords: [DiaryRecord] = []
    for recordID in self.dateOrderedIndexData {
      let record = self.dataModel.retrieveDiaryRecordByID(recordID)
      assert(record != nil, "Inconsistency of Index")
      sortedRecords.append(record!)
    }
    //sortedRecords.sortInPlace({$0.creationDate < $1.creationDate })
    return sortedRecords
  }
  
  // You give an index of today records array returned erlier,
  // this method gives you identifier to be used in DataModel
  // class for update, remove, etc..
  // WARNING: These indices are invalidated after model change.
  func getModelRecordIdByTodayRecordIndex(todayId: Int) -> Int {
    rebuildDateRecordsCacheIfNecessary()
    let modelIndex: Int = self.todayRecordsIndex[todayId]
    return modelIndex
  }
  
  func getModelRecordIdByThisWeekRecordIndex(thisWeekId: Int) -> Int {
    rebuildDateRecordsCacheIfNecessary()
    let recordID = self.thisWeekRecordsIndex[thisWeekId]
    return recordID
  }
  
  func getModelRecordIdByErlierRecordIndex(erlierId: Int) -> Int {
    rebuildDateRecordsCacheIfNecessary()
    let recordID = self.erlierRecordsIndex[erlierId]
    return recordID
  }
  
  func getModelRecordByMoodOrderedIndex(mood: RecordMood, index: Int) -> Int {
    rebuildDateRecordsCacheIfNecessary()
    if let indexForMood = self.moodOrderedIndexData[mood] {
      let recordID = indexForMood[index]
      return recordID
    }
    assert(false, "Invalid erlierId value \(index) or inconsistent index")
  }
  
  // MARK: - Implementation
  
  private func rebuildDateRecordsCacheIfNecessary() {
    if !cacheValid {
      NSLog("Rebuilding date categorization cache..")
      buildDateCategorizedIndex()
      buildSortedOrderedIndex()
      cacheValid = true
    }
    if (!moodCacheValid) {
      NSLog("Rebuilding mood categorization cache..")
      buildMoodOredredIndex()
      moodCacheValid = true
    }
  }
  
  private func buildDataComponentsFor(date: NSDate) -> NSDateComponents {
    let flags = self.dateComponentsRetrievalFlags
    let todayComponents = NSCalendar.currentCalendar().components(flags, fromDate: date)
    return todayComponents
  }
  
  private func areDateDaysSame(thisDate: NSDate, asDate thatDate: NSDate) -> Bool {
    let this = buildDataComponentsFor(thisDate)
    let that = buildDataComponentsFor(thatDate)
    return this.year == that.year &&
      this.month == that.month &&
      this.day == that.day
  }
  
  private func areDateWeaksSame(thisDate: NSDate, asDate thatDate: NSDate) -> Bool {
    let this = buildDataComponentsFor(thisDate)
    let that = buildDataComponentsFor(thatDate)
    return this.year == that.year &&
      this.month == that.month &&
      this.weekOfMonth == that.weekOfMonth
  }
  
  private func buildDateCategorizedIndex() {
    self.todayRecordsIndex.removeAll()
    self.thisWeekRecordsIndex.removeAll()
    self.erlierRecordsIndex.removeAll()
    let allRecords = self.dataModel.retrieveAllDiaryRecords()
    for (recordID, record) in allRecords {
      let today = NSDate()
      if areDateDaysSame(today, asDate: record.creationDate) {
        self.todayRecordsIndex.append(recordID)
      } else if areDateWeaksSame(today, asDate: record.creationDate) {
        self.thisWeekRecordsIndex.append(recordID)
      } else {
        self.erlierRecordsIndex.append(recordID)
      }
    }
    // Inside each section, we want to have records sorted
    self.todayRecordsIndex.sortInPlace() {
      return allRecords[$0]!.creationDate < allRecords[$1]!.creationDate
    }
    self.thisWeekRecordsIndex.sortInPlace() {
      return allRecords[$0]!.creationDate < allRecords[$1]!.creationDate
    }
    self.erlierRecordsIndex.sortInPlace() {
      return allRecords[$0]!.creationDate < allRecords[$1]!.creationDate
    }
    
    NSLog("DateCategorized cache has been updated:")
    NSLog("todayRecordsIndex: \(todayRecordsIndex)")
    NSLog("thisWeekRecordsIndex: \(thisWeekRecordsIndex)")
    NSLog("erlierRecordsIndex: \(erlierRecordsIndex)")
  }
  
  private func buildSortedOrderedIndex() {
    let dataRecords = self.dataModel.retrieveAllDiaryRecords()
    self.dateOrderedIndexData.removeAll()
    for (recordID, _) in dataRecords {
      self.dateOrderedIndexData.append(recordID)
    }
    self.dateOrderedIndexData.sortInPlace({
      let thisRecord = self.dataModel.getDiaryRecordRefByID($0)
      let thatRecord = self.dataModel.getDiaryRecordRefByID($1)
      assert(thisRecord != nil, "Inconsistency of Index")
      assert(thatRecord != nil, "Inconsistency of Index")
      return thisRecord!.creationDate < thatRecord!.creationDate
    })
  }
  
  private func buildMoodOredredIndex() {
    let allMoods: [RecordMood] = [.NoSet, .Neutral, .Bad, .Good]
    for mood in allMoods {
      self.moodOrderedIndexData[mood]?.removeAll()
    }
    let dataRecords = self.dataModel.retrieveAllDiaryRecords()
    for (recordID, record) in dataRecords {
      self.moodOrderedIndexData[record.mood]?.append(recordID)
    }
    for mood in allMoods {
      self.moodOrderedIndexData[mood]?.sortInPlace() {
        let thisRecord = dataRecords[$0]
        let thatRecord = dataRecords[$1]
        return thisRecord!.creationDate < thatRecord!.creationDate
      }
    }
  }
  
  private func notifyRecordAdded(id: RecordID) -> Void {
    if self.delegate != nil {
      self.delegate!.recordAdded(id)
    }
  }
  
  private func notifyRecordUpdated(id: RecordID) -> Void {
    if self.delegate != nil {
      self.delegate!.recordUpdated(id)
    }
  }
  
  private func notifyRecordRemoved(id: RecordID) -> Void {
    if self.delegate != nil {
      self.delegate!.recordRemoved(id)
    }
  }
  
  // MARK: - DataModelDelegate methods
  
  func recordUpdated(recordId: RecordID, old: DiaryRecord, new: DiaryRecord) -> Void {
    self.moodCacheValid = false
    self.cacheValid = false
    notifyRecordUpdated(recordId)
  }
  
  func recordInserted(recordId: RecordID, record: DiaryRecord) -> Void {
    self.moodCacheValid = false
    self.cacheValid = false
    notifyRecordAdded(recordId)
  }
  
  func recordDropped(recordId: RecordID, record: DiaryRecord) -> Void {
    self.moodCacheValid = false
    self.cacheValid = false
    notifyRecordRemoved(recordId)
  }
}
