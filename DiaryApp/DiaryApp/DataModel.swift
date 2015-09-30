//
//  DataModel.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/27/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import Foundation

typealias RecordID = Int

protocol DataModelDelegate : class {
//  func dataModelCollectionChanged() -> Void
  func recordUpdated(recordId: RecordID, old: DiaryRecord, new: DiaryRecord) -> Void
  func recordInserted(recordId: RecordID, record: DiaryRecord) -> Void
  func recordDropped(recordId: RecordID, record: DiaryRecord) -> Void
}

// For the sake of simplicity, assume that data is singleton.
class DataModel{
  static let sharedInstance = DataModel()
  private var recordsCollection: Dictionary<RecordID, DiaryRecord> = [:]
  var currentRecordID: RecordID = 0
  weak var delegate: DataModelDelegate? = nil
  var recordsCount: Int { get {
      return recordsCollection.count
    }
  }
  
  func generateRecordId() -> RecordID {
    let newRecordID = self.currentRecordID
    ++self.currentRecordID
    return newRecordID
  }
  
  func initFromArray(data: [DiaryRecord]) {
    assert(self.recordsCollection.isEmpty) // Method can only deal with initializations
    for record in data {
      let id = generateRecordId()
      self.recordsCollection[id] = record
    }
  }
  
  func addDiaryRecord(record: DiaryRecord) -> RecordID{
    let id = generateRecordId()
    recordsCollection[id] = record
    notifyRecordInserted(id, record: record)
    return id
  }
  
  func removeDiaryRecordByID(id: RecordID) {
    let droppedRecord = self.recordsCollection.removeValueForKey(id)
    assert(droppedRecord != nil, "No such records.")
    notifyRecordDropped(id, record: droppedRecord!)
  }
  
  func updateDiaryRecorByID(id: RecordID, updateCb: (DiaryRecord) -> Void) {
    let record = self.recordsCollection[id]
    assert(record != nil)
    let previousRecord = record!.copy() as! DiaryRecord
    updateCb(record!)
    // record! should be updated now as was passed by reference.
    assert(record! === self.recordsCollection[id])
    notifyRecordUpdated(id, old: previousRecord, new: record!)
  }
  
  func retrieveAllDiaryRecordValues() -> [DiaryRecord] {
    let array =  [DiaryRecord](recordsCollection.values)
    return array
  }
  
  func retrieveAllDiaryRecords() -> [ RecordID: DiaryRecord ] {
    return recordsCollection
  }
  
  func getDiaryRecordRefByID(id: RecordID) -> DiaryRecord? {
    let record = self.recordsCollection[id]
    return record
  }
  
  func retrieveDiaryRecordByID(id: RecordID) -> DiaryRecord? {
    let record = self.recordsCollection[id]
    if let record = record {
      return record.copy() as? DiaryRecord
    }
    return nil
  }
  
  func notifyRecordUpdated(recordId: RecordID, old: DiaryRecord, new: DiaryRecord) -> Void {
    if self.delegate != nil {
      self.delegate!.recordUpdated(recordId, old: old, new: new)
    }
  }

  func notifyRecordInserted(recordId: RecordID, record: DiaryRecord) -> Void {
    if self.delegate != nil {
      self.delegate!.recordInserted(recordId, record: record)
    }
  }
  
  func notifyRecordDropped(recordId: RecordID, record: DiaryRecord) -> Void {
    if self.delegate != nil {
      self.delegate!.recordDropped(recordId, record: record)
    }
  }
}

protocol DataModelUIProxyDelegate : class {
  func recordAdded(id: RecordID) -> Void
  func recordUpdated(id: RecordID) -> Void
  func recordRemoved(id: RecordID) -> Void
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
  private var moodCacheValid: Bool
  private weak var delegate: DataModelUIProxyDelegate?
  
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
  
  func retrieveTodayRecords() -> [DiaryRecord] {
    rebuildDateRecordsCacheIfNecessary()
    // TODO: Reserve memory for ahead
    var todayRecords: Array<DiaryRecord> = []
    for recordId in self.todayRecordsIndex {
      if let record = self.dataModel.retrieveDiaryRecordByID(recordId) {
        todayRecords.append(record)
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
  
  func retrieveTheseWeekRecords() -> [DiaryRecord] {
    rebuildDateRecordsCacheIfNecessary()
    // TODO: Reserve memory for ahead
    var weekRecords: Array<DiaryRecord> = []
    for recordId in self.thisWeekRecordsIndex {
      let record = self.dataModel.retrieveDiaryRecordByID(recordId)
      assert(record != nil, "Inconsistency of Index")
      weekRecords.append(record!)
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
  
  func retrieveErlierRecords() -> [DiaryRecord] {
    rebuildDateRecordsCacheIfNecessary()
    // TODO: Reserve memory for ahead
    var erlierRecords: Array<DiaryRecord> = []
    for recordId in self.erlierRecordsIndex {
      let record = self.dataModel.retrieveDiaryRecordByID(recordId)
      assert(record != nil, "Inconsistency of Index")
      erlierRecords.append(record!)
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
  
  func buildDateCategorizedIndex() {
    self.todayRecordsIndex.removeAll()
    self.thisWeekRecordsIndex.removeAll()
    self.erlierRecordsIndex.removeAll()
    for (recordID, record) in self.dataModel.retrieveAllDiaryRecords() {
      let today = NSDate()
      if areDateDaysSame(today, asDate: record.creationDate) {
        self.todayRecordsIndex.append(recordID)
      } else if areDateWeaksSame(today, asDate: record.creationDate) {
        self.thisWeekRecordsIndex.append(recordID)
      } else {
        self.erlierRecordsIndex.append(recordID)
      }
    }
    NSLog("DateCategorized cache has been updated:")
    NSLog("todayRecordsIndex: \(todayRecordsIndex)")
    NSLog("thisWeekRecordsIndex: \(thisWeekRecordsIndex)")
    NSLog("erlierRecordsIndex: \(erlierRecordsIndex)")
  }
  
  func buildSortedOrderedIndex() {
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
  
  func buildMoodOredredIndex() {
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
  
  func notifyRecordAdded(id: RecordID) -> Void {
    if self.delegate != nil {
      self.delegate!.recordAdded(id)
    }
  }
  
  func notifyRecordUpdated(id: RecordID) -> Void {
    if self.delegate != nil {
      self.delegate!.recordUpdated(id)
    }
  }
  
  func notifyRecordRemoved(id: RecordID) -> Void {
    if self.delegate != nil {
      self.delegate!.recordRemoved(id)
    }
  }
  
  // MARK: - DataModelDelegate methods

  // TODO: Make correct cache update
  func recordUpdated(recordId: RecordID, old: DiaryRecord, new: DiaryRecord) -> Void {
    self.moodCacheValid = false
    self.cacheValid = false
    notifyRecordUpdated(recordId)
  }

  // TODO: Make correct cache update
  func recordInserted(recordId: RecordID, record: DiaryRecord) -> Void {
    self.moodCacheValid = false
    self.cacheValid = false
    notifyRecordAdded(recordId)
  }
  
  // TODO: Make correct cache update
  func recordDropped(recordId: RecordID, record: DiaryRecord) -> Void {
    self.moodCacheValid = false
    self.cacheValid = false
    notifyRecordRemoved(recordId)
  }
}

////////////////////////////////////////////////////////////////////////



protocol CreationDateCategorizationDataModelProxyDelegate : class {
  func sectionCreated(sectionIndex: Int) -> Void
  func sectionDestroyed(sectionIndex: Int) -> Void
  func rowDeleted(section: Int, row: Int) -> Void
  func rowInserted(section: Int, row: Int) -> Void
  func rowUpdated(section: Int, row: Int) -> Void
}


class CreationDateCategorizationDataModelProxy: DataModelUIProxyDelegate {
  let proxy: DataModelUIProxy
  weak var delegate: CreationDateCategorizationDataModelProxyDelegate?
  
  enum RecordsCategory { case Today; case ThisWeek; case Erlier }
  
  // Keep track of current table configuration: sections count, their categories and sizes.
  struct SectionInfo {
    let rowsCount: Int
    let category: RecordsCategory
    let rows: [DiaryRecord]
    
    init(rowsCount: Int, category: RecordsCategory, rows: [DiaryRecord]) {
      self.rowsCount = rowsCount
      self.category = category
      self.rows = rows
    }
  }
  
  class TableInfo : NSObject, NSCopying {
    var sectionsCount: Int = 0
    var sections: [Int: SectionInfo] = [:]
    
    func copyWithZone(zone: NSZone) -> AnyObject {
      let newTableInfo = TableInfo()
      newTableInfo.sectionsCount = self.sectionsCount
      newTableInfo.sections = self.sections
      return newTableInfo
    }
  }
  
  typealias SectionAddedCB = (section: Int) -> Void
  typealias SectionRemovedCB = (section: Int) -> Void
  typealias RowInsertedCB = (section: Int, row: Int) -> Void
  typealias RowRemovedCB = (section: Int, row: Int) -> Void
  
  func compareTableInfos(a a: TableInfo, b: TableInfo, sectionAdded: SectionAddedCB,
      sectionRemoved: SectionRemovedCB, rowInserted: RowInsertedCB, rowRemoved: RowRemovedCB) {
    
  }
  
  var currentTableInfo = TableInfo()

  func resolveActualTableInfo() -> TableInfo {
    let actualTableInfo = TableInfo()
    actualTableInfo.sectionsCount = doGetNumberOfSections()
    for sectionIdx in 0..<actualTableInfo.sectionsCount {
      let category = decodeRecordCategoryForSection(sectionIdx)
      var rows: [DiaryRecord]? = nil
      switch category {
      case .Today:
        rows = self.proxy.retrieveTodayRecords()
      case .ThisWeek:
        rows = self.proxy.retrieveTheseWeekRecords()
      case .Erlier:
        rows = self.proxy.retrieveErlierRecords()
      }
      let sectionInfo = SectionInfo(rowsCount: rows!.count, category: category, rows: rows!)
      actualTableInfo.sections[sectionIdx] = sectionInfo
    }
    return actualTableInfo
  }
  
  func updateCurrentTableInfoIfNecessary() -> Void {
    NSLog("updateCurrentTableInfoIfNecessary: Resolving actual table info")
    let latestTableInfo = resolveActualTableInfo()
    NSLog("updateCurrentTableInfoIfNecessary: Ccompare with existing")
    compareTableInfos(a: latestTableInfo, b: self.currentTableInfo,
      sectionAdded: { (section: Int) in
        NSLog("Section Created: \(section)")
        self.notifySectionCreated(section)
      },
      sectionRemoved: { (section: Int) in
        NSLog("Section Removed: \(section)")
        self.notifySectionDestroyed(section)
      },
      rowInserted: { (section: Int, row: Int) in
        NSLog("Row \(row) inserted to section: \(section)")
        self.notifyRowInserted(section, row: row)
      },
      rowRemoved: { (section: Int, row: Int) in
        NSLog("Row \(row) removed from section: \(section)")
        self.notifyRowDeleted(section, row: row)
      }
    )
  }
  
  // MARK: - DataModelUIProxyDelegate
  
  func recordAdded(id: RecordID) -> Void {
    updateCurrentTableInfoIfNecessary()
  }
  
  func recordUpdated(id: RecordID) -> Void {
    updateCurrentTableInfoIfNecessary()
  }
  
  func recordRemoved(id: RecordID) -> Void {
    updateCurrentTableInfoIfNecessary()
  }

  func notifySectionCreated(sectionIndex: Int) {
    if self.delegate != nil {
      self.delegate?.sectionCreated(sectionIndex)
    }
  }
  
  func notifySectionDestroyed(sectionIndex: Int) {
    if self.delegate != nil {
      self.delegate?.sectionDestroyed(sectionIndex)
    }
  }
  
  func notifyRowDeleted(section: Int, row: Int) {
    if self.delegate != nil {
      self.delegate?.rowDeleted(section, row: row)
    }
  }
  
  func notifyRowInserted(section: Int, row: Int) {
    if self.delegate != nil {
      self.delegate?.rowInserted(section, row: row)
    }
  }
  func notifyRowUpdated(section: Int, row: Int) {
    if self.delegate != nil {
      self.delegate?.rowUpdated(section, row: row)
    }
  }
  
  
  init(proxy: DataModelUIProxy) {
    self.proxy = proxy
    self.delegate = nil
  }
  
  func getSectionsCount() -> Int {
    return doGetNumberOfSections()
  }
  
  func getSectionNameByIndex(section: Int) -> String {
    return doGetSectionHeaderTitle(section)
  }
  
  func getSectionRowsCountBySection(section: Int) -> Int {
    return doGetRowsCountForSection(section)
  }
  
  // MARK: - Internal
  

  
  func decodeRecordCategoryForSection(section: Int) -> RecordsCategory {
    let todayRecordsCount = self.proxy.todayRecordsCount
    let thisWeekRecordsCount = self.proxy.thisWeekRecordsCount
    let erlierRecordsCount = self.proxy.erlierRecordsCount
    switch section  {
    case MasterViewController.TodayRecordsTableSectionIndex:
      if todayRecordsCount > 0 { return .Today }
      if thisWeekRecordsCount > 0 { return .ThisWeek }
      if erlierRecordsCount > 0 { return .Erlier }
      assert(false, "This method is coded in way it does not support cases when all sections are empty")
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
    case .Today: return self.proxy.getTodayRecordAtIndex(indexPath.row)
    case .ThisWeek: return self.proxy.getThisWeelRecordAtIndex(indexPath.row)
    case .Erlier: return self.proxy.getErlierRecordAtIndex(indexPath.row)
    }
  }
  
  func getDataRecordModelIdForIndexPath(indexPath: NSIndexPath) -> Int {
    let category = decodeRecordCategoryForSection(indexPath.section)
    switch category {
    case .Today: return self.proxy.getModelRecordIdByTodayRecordIndex(indexPath.row)
    case .ThisWeek: return self.proxy.getModelRecordIdByThisWeekRecordIndex(indexPath.row)
    case .Erlier: return self.proxy.getModelRecordIdByErlierRecordIndex(indexPath.row)
    }
  }
  
  func doGetNumberOfSections() -> Int {
    var sectionsCount = 0
    if self.proxy.todayRecordsCount > 0 { sectionsCount += 1 }
    if self.proxy.thisWeekRecordsCount > 0 { sectionsCount += 1 }
    if self.proxy.erlierRecordsCount > 0 { sectionsCount += 1 }
    return sectionsCount
  }
  
  func doGetRowsCountForSection(section: Int) -> Int {
    let category = decodeRecordCategoryForSection(section)
    switch category {
    case .Today:
      return self.proxy.todayRecordsCount
    case .ThisWeek:
      return self.proxy.thisWeekRecordsCount
    case .Erlier:
      return self.proxy.erlierRecordsCount
    }
  }
  
  func doGetSectionHeaderTitle(section: Int) -> String {
    let category = decodeRecordCategoryForSection(section)
    switch category {
    case .Today: return "Today"
    case .ThisWeek: return "This Week"
    case .Erlier: return "Erlier"
    }
  }
}

class MoodCategorizationDataModelProxy {
  let proxy: DataModelUIProxy

  init(proxy: DataModelUIProxy) {
    self.proxy = proxy
  }
}

class DataModelProxiesFactory {
  static let proxy = DataModelUIProxy(dataModel: DataModel.sharedInstance)
  
  static func getCreationDateCategorizationDataModelProxy() -> CreationDateCategorizationDataModelProxy {
    return CreationDateCategorizationDataModelProxy(proxy: self.proxy)
  }
  
  static func getMoodCategirizationDataModelProxy() -> MoodCategorizationDataModelProxy {
    return MoodCategorizationDataModelProxy(proxy: self.proxy)
  }
}

