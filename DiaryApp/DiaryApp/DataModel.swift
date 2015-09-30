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
  
  func buildDateCategorizedIndex() {
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
  
  // MARK: - Interface
  func synchronizeWithExistingData() {
    self.proxy.synchronizeWithExistingData()
  }
  
  // MARK: - Implementation details
  
  // Keep track of current table configuration: sections count, their categories and sizes.
  struct SectionInfo {
    let rowsCount: Int
    let category: RecordsCategory
    let rows: [(RecordID, DiaryRecord)]
    
    init(rowsCount: Int, category: RecordsCategory, rows: [(RecordID, DiaryRecord)]) {
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
    let hasDiffs = compareTableInfoForSectionsDiff(a: a, b: b, sectionAdded: sectionAdded,
      sectionRemoved: sectionRemoved, rowInserted: rowInserted, rowRemoved: rowRemoved)
    if hasDiffs {
      return
    }
        
    // Check rows structure for non-changed sections
    compareTableInfoForRowsDiff(a: a, b: b, rowInserted: rowInserted, rowRemoved: rowRemoved)
  }
  
  func compareTableInfoForSectionsDiff(a a: TableInfo, b: TableInfo, sectionAdded: SectionAddedCB, sectionRemoved: SectionRemovedCB,
      rowInserted: RowInsertedCB, rowRemoved: RowRemovedCB) -> Bool {
    var foundDiffs = false
    let a_sectionsCategories: [(RecordsCategory, Int)] = a.sections.map() { (sIdx, sInfo) in (sInfo.category, sIdx) }
    let b_sectionsCategories: [(RecordsCategory, Int)] = b.sections.map() { (sIdx, sInfo) in (sInfo.category, sIdx) }
    var DA = Dictionary<RecordsCategory, Int>()
    var DB = Dictionary<RecordsCategory, Int>()
    for (category, sectionIdx) in a_sectionsCategories { DA[category] = sectionIdx }
    for (category, sectionIdx) in b_sectionsCategories { DB[category] = sectionIdx }
    for (category, sectionIdx) in DA {
      if DB[category] == nil {
        // Befire section removed, all records removed
        // IMPORTANT: Due to specific behaviour of UITableView, if last record on last record removing,
        // we need remove a section instead of row.
        let wasRowsInSection = a.sections[sectionIdx]!.rows.count
        for (rowIdx, _) in a.sections[sectionIdx]!.rows.enumerate() {
          if rowIdx == wasRowsInSection - 1 {
            // Skip last!
            break
          }
          rowRemoved(section: sectionIdx, row: rowIdx)
        }
        sectionRemoved(section: sectionIdx)
        foundDiffs = true
      }
      DB.removeValueForKey(category)
    }
    for (_, sectionIdx) in DB {
      sectionAdded(section: sectionIdx);
      // Notfify also about rows added to this section
      for (rowIdx, _) in b.sections[sectionIdx]!.rows.enumerate() {
        rowInserted(section: sectionIdx, row: rowIdx)
      }
      foundDiffs = true
    }
    return foundDiffs
  }
  
  func compareTableInfoForRowsDiff(a a: TableInfo, b: TableInfo, rowInserted: RowInsertedCB, rowRemoved: RowRemovedCB) {
    // NOTE: Sections should be already checked for equality
    let sectionsCount = a.sectionsCount
    assert(a.sections.count == b.sections.count)
    for sectionIdx in 0..<sectionsCount {
      let a_sectionInfo = a.sections[sectionIdx]
      let b_sectionInfo = b.sections[sectionIdx]
      assert(a_sectionInfo != nil && b_sectionInfo != nil)
      assert(a_sectionInfo!.category == b_sectionInfo!.category)
      compareSectionsForRowDiff(section: sectionIdx, a: a_sectionInfo!, b: b_sectionInfo!,
        rowInserted: rowInserted, rowRemoved: rowRemoved)
    }
  }
  
  func compareSectionsForRowDiff(section section: Int, a: SectionInfo, b: SectionInfo, rowInserted: RowInsertedCB, rowRemoved: RowRemovedCB)  {
    typealias RecordPosition = Int
    var a_rows_hash: Dictionary<Int, (RecordID, (RecordPosition, DiaryRecord))>= [:]
    var b_rows_hash: Dictionary<Int, (RecordID, (RecordPosition, DiaryRecord))>= [:]
    for (index, row) in a.rows.enumerate() { a_rows_hash[row.0] = (index, row) }
    for (index, row) in b.rows.enumerate() { b_rows_hash[row.0] = (index, row) }
    for (modelId, rowRec) in a_rows_hash  {
      if b_rows_hash[modelId] == nil {
        let position = rowRec.0
        rowRemoved(section: section, row: position)
      }
      b_rows_hash.removeValueForKey(modelId)
    }
    for (/*modelId*/_, rowRec) in b_rows_hash {
      let position = rowRec.0
      rowInserted(section: section, row: position)
    }
  }
  
  var currentTableInfo = TableInfo()

  func resolveActualTableInfo() -> TableInfo {
    let actualTableInfo = TableInfo()
    actualTableInfo.sectionsCount = doGetNumberOfSections()
    for sectionIdx in 0..<actualTableInfo.sectionsCount {
      let category = decodeRecordCategoryForSection(sectionIdx)
      var rows: [(RecordID, DiaryRecord)]? = nil
      switch category {
      case .Today: rows = self.proxy.retrieveTodayRecords()
      case .ThisWeek: rows = self.proxy.retrieveTheseWeekRecords()
      case .Erlier: rows = self.proxy.retrieveErlierRecords()
      }
      let sectionInfo = SectionInfo(rowsCount: rows!.count, category: category, rows: rows!)
      actualTableInfo.sections[sectionIdx] = sectionInfo
    }
    return actualTableInfo
  }
  
  func updateCurrentTableInfoIfNecessary() -> Void {
    let latestTableInfo = resolveActualTableInfo()
    compareTableInfos(a: self.currentTableInfo, b: latestTableInfo,
      sectionAdded: { (section: Int) in self.notifySectionCreated(section) },
      sectionRemoved: { (section: Int) in self.notifySectionDestroyed(section) },
      rowInserted: { (section: Int, row: Int) in self.notifyRowInserted(section, row: row) },
      rowRemoved: { (section: Int, row: Int) in self.notifyRowDeleted(section, row: row) }
    )
    self.currentTableInfo = latestTableInfo
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
    self.proxy.delegate = self
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
  static func getCreationDateCategorizationDataModelProxy(dataModel dataModel: DataModel) -> CreationDateCategorizationDataModelProxy {
    let proxy = DataModelUIProxy(dataModel: dataModel)
    return CreationDateCategorizationDataModelProxy(proxy: proxy)
  }
  
  static func getMoodCategirizationDataModelProxy(dataModel: DataModel) -> MoodCategorizationDataModelProxy {
    let proxy = DataModelUIProxy(dataModel: dataModel)
    return MoodCategorizationDataModelProxy(proxy: proxy)
  }
}

