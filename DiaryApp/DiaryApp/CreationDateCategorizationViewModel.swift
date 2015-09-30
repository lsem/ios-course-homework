//
//  CreationDateCategorizationViewModel.swift
//  DiaryApp
//
//  Created by Lyubomyr Semkiv on 9/30/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import UIKit

protocol CreationDateCategorizationViewModelDelegate : class {
  func sectionCreated(sectionIndex: Int) -> Void
  func sectionDestroyed(sectionIndex: Int) -> Void
  func rowDeleted(section: Int, row: Int, lastRecord: Bool) -> Void
  func rowInserted(section: Int, row: Int) -> Void
  func rowUpdated(section: Int, row: Int) -> Void
}

class CreationDateCategorizationViewModel: DataModelIndexingProxyDelegate {
  let proxy: DataModelIndexingProxy
  weak var delegate: CreationDateCategorizationViewModelDelegate?
  
  enum RecordsCategory { case Today; case ThisWeek; case Erlier }
  
  // MARK: - Interface
  
  // Method needed to pump initial events records when data loaded form external source
  // while delegate was not listening for events. So that, by calling this methods
  // events like SectionCreated, RecordInserted will arive for all current data.
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
  typealias RowRemovedCB = (section: Int, row: Int, lastRecord: Bool) -> Void
  
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
          // Before section removed, all records removed
          let wasRowsInSection = a.sections[sectionIdx]!.rows.count
          for (rowIdx, _) in a.sections[sectionIdx]!.rows.enumerate() {
            let lastRecord = rowIdx == wasRowsInSection - 1
            rowRemoved(section: sectionIdx, row: rowIdx, lastRecord: lastRecord)
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
        rowRemoved(section: section, row: position, lastRecord: false)
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
      rowRemoved: { (section: Int, row: Int, lastRecord: Bool) in self.notifyRowDeleted(section, row: row, lastRecord: lastRecord) }
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
  
  func notifyRowDeleted(section: Int, row: Int, lastRecord: Bool) {
    if self.delegate != nil {
      self.delegate?.rowDeleted(section, row: row, lastRecord: lastRecord)
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
  
  init(proxy: DataModelIndexingProxy) {
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

