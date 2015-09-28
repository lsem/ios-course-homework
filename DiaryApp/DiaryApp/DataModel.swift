//
//  DataModel.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/27/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import Foundation

protocol DataModelDelegate {
  func dataModelCollectionChanged() -> Void
  func recordUpdated(old: DiaryRecord, new: DiaryRecord) -> Void
}

// For the sake of simplicity, assume that data is singleton.
class DataModel{
  static let sharedInstance = DataModel()
  private var recordsCollection: [DiaryRecord] = []
  var delegate: DataModelDelegate? = nil
  var recordsCount: Int { get {
      return recordsCollection.count
    }
  }
  
  func initFromArray(data: [DiaryRecord]) {
      self.recordsCollection = data
  }
  
  func addDiaryRecord(record: DiaryRecord) {
    recordsCollection.append(record)
    notifyCollectionChange()
  }
  
  func removeDiaryRecordAt(index index: Int) {
    self.recordsCollection.removeAtIndex(index)
    notifyCollectionChange()
  }
  
  func updateDiaryRecordAt(index index: Int, updateCb: (DiaryRecord) -> Void) {
    let ref = self.recordsCollection[index]
    let recordBeforeUpdate = DiaryRecord(name: ref.name, text: ref.text,
        mood: ref.mood, creationDate: ref.creationDate)
    
    updateCb(self.recordsCollection[index])
    
    let recordAfterUpdate = self.recordsCollection[index]
    notifyRecordUpdated(recordBeforeUpdate, new: recordAfterUpdate)
  }
  
  // Retrieves all available records in unspecified order but STABLE so that
  // after retrieving some data, one can assume indexes will not change (like sequential storage).
  func retrieveAllDiaryRecords() -> [DiaryRecord] {
    return recordsCollection
  }
  
  func retrieveDiaryRecordAt(index index: Int) -> DiaryRecord? {
    if index < self.recordsCollection.count {
      let recordCopy = self.recordsCollection[index].copy() as? DiaryRecord
      return  recordCopy
    }
    return nil
  }
  
  internal func notifyCollectionChange() {
    if self.delegate != nil {
      self.delegate!.dataModelCollectionChanged()
    }
  }

  internal func notifyRecordUpdated(old: DiaryRecord, new: DiaryRecord) {
    if self.delegate != nil {
      self.delegate!.recordUpdated(old, new: new)
    }
  }
  
}

// This class is UItableView specific and in general should be
// places into separate unit.
class DataModelUIProxy : DataModelDelegate {
  private var dataModel: DataModel
  private var creationDataIndex: Array<Int>
  private var todayRecordsIndex: Array<Int>
  private var thisWeekRecordsIndex: Array<Int>
  private var erlierRecordsIndex: Array<Int>
  private var dateOrderedIndexData: Array<Int>
  private var moodOrderedIndexData: Dictionary<RecordMood, Array<Int>>
  private var cacheValid: Bool

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
    self.dataModel.delegate = self
  }
  
  // MARK: - Public methods and properties

  var todayRecordsCount: Int { get {
    rebuildDateRecordsCacheIfNecessary()
    return self.todayRecordsIndex.count
    }
  }

  func getTodayRecordAtIndex(index: Int) -> DiaryRecord {
    let index = getModelRecordIdByTodayRecordIndex(index)
    return self.dataModel.recordsCollection[index]
  }
  
  func retrieveTodayRecords() -> [DiaryRecord] {
    rebuildDateRecordsCacheIfNecessary()
    // TODO: Reserve memory for ahead
    var todayRecords: Array<DiaryRecord> = []
    let allRecords: [DiaryRecord] = self.dataModel.retrieveAllDiaryRecords()
    for index in self.todayRecordsIndex {
      todayRecords.append(allRecords[index])
    }
    return todayRecords
  }
  
  var thisWeekRecordsCount: Int { get {
    rebuildDateRecordsCacheIfNecessary()
    return self.thisWeekRecordsIndex.count
    }
  }

  func getThisWeelRecordAtIndex(index: Int) -> DiaryRecord {
    let index = getModelRecordIdByThisWeekRecordIndex(index)
    return self.dataModel.recordsCollection[index]
  }
  
  func retrieveTheseWeekRecords() -> [DiaryRecord] {
    rebuildDateRecordsCacheIfNecessary()
    // TODO: Reserve memory for ahead
    var weekRecords: Array<DiaryRecord> = []
    let allRecords: [DiaryRecord] = self.dataModel.retrieveAllDiaryRecords()
    for index in self.thisWeekRecordsIndex {
      weekRecords.append(allRecords[index])
    }
    return weekRecords
  }
  
  var erlierRecordsCount: Int { get {
      rebuildDateRecordsCacheIfNecessary()
      return self.erlierRecordsIndex.count
    }
  }
  
  func getErlierRecordAtIndex(index: Int) -> DiaryRecord {
    let index = getModelRecordIdByErlierRecordIndex(index)
    return self.dataModel.recordsCollection[index]
  }  
  
  func retrieveErlierRecords() -> [DiaryRecord] {
    rebuildDateRecordsCacheIfNecessary()
    // TODO: Reserve memory for ahead
    var erlierRecords: Array<DiaryRecord> = []
    let allRecords: [DiaryRecord] = self.dataModel.retrieveAllDiaryRecords()
    for index in self.erlierRecordsIndex {
      erlierRecords.append(allRecords[index])
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
    let modelIndex = getModelRecordByMoodOrderedIndex(mood, index: index)
    return self.dataModel.recordsCollection[modelIndex]
  }
  
  func retrieveAllRecordsSortedByCreationDate() -> [DiaryRecord] {
    rebuildDateRecordsCacheIfNecessary()
    var allRecords = self.dataModel.retrieveAllDiaryRecords()
    var sortedRecords: [DiaryRecord] = []
    sortedRecords.reserveCapacity(allRecords.count)
    for idx in self.dateOrderedIndexData {
        sortedRecords.append(allRecords[idx])
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
    let modelIndex: Int = self.thisWeekRecordsIndex[thisWeekId]
    return modelIndex
  }
  
  func getModelRecordIdByErlierRecordIndex(erlierId: Int) -> Int {
    rebuildDateRecordsCacheIfNecessary()    
    let modelIndex: Int = self.erlierRecordsIndex[erlierId]
    return modelIndex
  }
  
  func getModelRecordByMoodOrderedIndex(mood: RecordMood, index: Int) -> Int {
    rebuildDateRecordsCacheIfNecessary()
    if let indexForMood = self.moodOrderedIndexData[mood] {
      let modelIndex: Int = indexForMood[index]
      return modelIndex
    }
    assert(false, "Invalid erlierId value \(index) or inconsistent index")
  }
  
  // MARK: - Implementation
  
  private func rebuildDateRecordsCacheIfNecessary() {
    if !cacheValid {
      NSLog("Rebuilding cache..")
      buildDateCategorizedIndex()
      buildSortedOrderedIndex()
      buildMoodOredredIndex()
      cacheValid = true
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
  
  func buildDateCategorizedIndex() {
    self.todayRecordsIndex.removeAll()
    self.thisWeekRecordsIndex.removeAll()
    self.erlierRecordsIndex.removeAll()
    let allRecords: [DiaryRecord] = self.dataModel.retrieveAllDiaryRecords()
    for (index, record) in allRecords.enumerate() {
      let today = NSDate()
      if areDateDaysSame(today, asDate: record.creationDate) {
        self.todayRecordsIndex.append(index)
      } else if areDateWeaksSame(today, asDate: record.creationDate) {
        self.thisWeekRecordsIndex.append(index)
      } else {
        self.erlierRecordsIndex.append(index)
      }
    }
    NSLog("DateCategorized cache has been updated:")
    NSLog("todayRecordsIndex: \(todayRecordsIndex)")
    NSLog("thisWeekRecordsIndex: \(thisWeekRecordsIndex)")
    NSLog("erlierRecordsIndex: \(erlierRecordsIndex)")
  }
  
  func buildSortedOrderedIndex() {
    var dataRecords = self.dataModel.retrieveAllDiaryRecords()
    self.dateOrderedIndexData = Array<Int>(count: dataRecords.count, repeatedValue: 0)
    for index in 0..<self.dateOrderedIndexData.count {
      self.dateOrderedIndexData[index] = index
    }
    self.dateOrderedIndexData.sortInPlace({
      dataRecords[$0].creationDate < dataRecords[$1].creationDate
    })
  }
  
  func buildMoodOredredIndex() {
    let allValues: [RecordMood] = [.NoSet, .Neutral, .Bad, .Good]
    for mood in allValues {
      self.moodOrderedIndexData[mood]?.removeAll()
    }
    let dataRecords = self.dataModel.retrieveAllDiaryRecords()
    for (index, record) in dataRecords.enumerate() {
      self.moodOrderedIndexData[record.mood]?.append(index)
    }
  }
  
  // MARK: - DataModelDelegate methods

  func dataModelCollectionChanged() -> Void {
    self.cacheValid = false
  }

  func recordUpdated(old: DiaryRecord, new: DiaryRecord) -> Void {
    // TODO: Once DiaryRecord will be correct in NSCopying sense, 
    // we should check whether date changed here!
    if old.creationDate != new.creationDate {
      self.cacheValid = false
    }
    if old.mood != new.mood {
      self.cacheValid = false
    }
  }
}



