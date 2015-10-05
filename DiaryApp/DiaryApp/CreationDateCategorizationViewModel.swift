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

// Instance of this class responsible for supporting UITableView with
// dynamically managed section. I.e if there are only today records, we have one section with index 0
// and it has appropriate header. If we add one more record into this week section, we have two sections
// where section 0 become ThisWeek and section 1 becomes today. So that, required functionality is
// providing actual information about number of sections, rows for each section, titles, etc.
// As well as notifiying UITableViewController about changes in structure. 
// Better implementation would more acurately keep track of its indices but this
// one do it somewhat wrong: on each change it makes difference between previous and current datamodel 
// (which should be read from indexing proxy). Even this is not coded in efficient way, but it can be in most cases
// if it will be needed. Important is that it looks correct and it has few tests proving this.
class CreationDateCategorizationViewModel: DataModelIndexingProxyDelegate {
  private let proxy: DataModelIndexingProxy
  private var currentTableInfo = TableInfo()
  weak var delegate: CreationDateCategorizationViewModelDelegate?
  
  enum RecordsCategory { case Today; case ThisWeek; case Erlier }
  
  // MARK: - Interface
  
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
  
  func getDiaryRecordByIndexPath(indexPath: NSIndexPath) -> DiaryRecord {
    let category = decodeRecordCategoryForSection(indexPath.section)
    switch category {
    case .Today: return self.proxy.getTodayRecordAtIndex(indexPath.row)
    case .ThisWeek: return self.proxy.getThisWeelRecordAtIndex(indexPath.row)
    case .Erlier: return self.proxy.getErlierRecordAtIndex(indexPath.row)
    }
  }
  
  func getDiaryRecordIdForIndexPath(indexPath: NSIndexPath) -> Int {
    let category = decodeRecordCategoryForSection(indexPath.section)
    switch category {
    case .Today: return self.proxy.getModelRecordIdByTodayRecordIndex(indexPath.row)
    case .ThisWeek: return self.proxy.getModelRecordIdByThisWeekRecordIndex(indexPath.row)
    case .Erlier: return self.proxy.getModelRecordIdByErlierRecordIndex(indexPath.row)
    }
  }
  
  // Method needed to pump initial events records when data loaded form external source
  // while delegate was not listening for events. So that, by calling this methods
  // events like SectionCreated, RecordInserted will arive for all current data.
  func synchronizeWithExistingData() {
    self.proxy.synchronizeWithExistingData()
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

  // MARK: - Implementation details
  
  // Keep track of current table configuration: sections count, their categories and sizes.
  private struct SectionInfo {
    let rowsCount: Int
    let category: RecordsCategory
    let rows: [(RecordID, DiaryRecord)]
    
    init(rowsCount: Int, category: RecordsCategory, rows: [(RecordID, DiaryRecord)]) {
      self.rowsCount = rowsCount
      self.category = category
      self.rows = rows
    }
  }
  
  private class TableInfo {
    var sectionsCount: Int = 0
    var sections: [Int: SectionInfo] = [:]
  }
  
  private typealias SectionAddedCB = (section: Int) -> Void
  private typealias SectionRemovedCB = (section: Int) -> Void
  private typealias RowInsertedCB = (section: Int, row: Int) -> Void
  private typealias RowRemovedCB = (section: Int, row: Int, lastRecord: Bool) -> Void
  
  private func compareTableInfos(a a: TableInfo, b: TableInfo, sectionAdded: SectionAddedCB,
    sectionRemoved: SectionRemovedCB, rowInserted: RowInsertedCB, rowRemoved: RowRemovedCB) {
      let hasDiffs = compareTableInfoForSectionsDiff(a: a, b: b, sectionAdded: sectionAdded,
        sectionRemoved: sectionRemoved, rowInserted: rowInserted, rowRemoved: rowRemoved)
      if hasDiffs {
        return
      }
      
      // Check rows structure for non-changed sections
      compareTableInfoForRowsDiff(a: a, b: b, rowInserted: rowInserted, rowRemoved: rowRemoved)
  }
  
  private func compareTableInfoForSectionsDiff(a a: TableInfo, b: TableInfo, sectionAdded: SectionAddedCB, sectionRemoved: SectionRemovedCB,
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
  
  private func compareTableInfoForRowsDiff(a a: TableInfo, b: TableInfo, rowInserted: RowInsertedCB, rowRemoved: RowRemovedCB) {
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
  
  private func compareSectionsForRowDiff(section section: Int, a: SectionInfo, b: SectionInfo, rowInserted: RowInsertedCB, rowRemoved: RowRemovedCB)  {
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
  
  private func resolveActualTableInfo() -> TableInfo {
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
  
  private func updateCurrentTableInfoIfNecessary() -> Void {
    let latestTableInfo = resolveActualTableInfo()
    compareTableInfos(a: self.currentTableInfo, b: latestTableInfo,
      sectionAdded: { (section: Int) in self.notifySectionCreated(section) },
      sectionRemoved: { (section: Int) in self.notifySectionDestroyed(section) },
      rowInserted: { (section: Int, row: Int) in self.notifyRowInserted(section, row: row) },
      rowRemoved: { (section: Int, row: Int, lastRecord: Bool) in self.notifyRowDeleted(section, row: row, lastRecord: lastRecord) }
    )
    self.currentTableInfo = latestTableInfo
  }
  
  private func decodeRecordCategoryForSection(section: Int) -> RecordsCategory {
    let todayRecordsCount = self.proxy.todayRecordsCount
    let thisWeekRecordsCount = self.proxy.thisWeekRecordsCount
    let erlierRecordsCount = self.proxy.erlierRecordsCount
    switch section  {
    case DateCategorizationTableViewController.TodayRecordsTableSectionIndex:
      if todayRecordsCount > 0 { return .Today }
      if thisWeekRecordsCount > 0 { return .ThisWeek }
      if erlierRecordsCount > 0 { return .Erlier }
      assert(false, "This method is coded in way it does not support cases when all sections are empty")
    case DateCategorizationTableViewController.ThisWeekRecordsTableSectionIndex:
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
    case DateCategorizationTableViewController.ErlierRecordsTableSectionIndex:
      assert(erlierRecordsCount > 0)
      return .Erlier
    default:
      assert(false)
    }
  }
  
  private func doGetNumberOfSections() -> Int {
    var sectionsCount = 0
    if self.proxy.todayRecordsCount > 0 { sectionsCount += 1 }
    if self.proxy.thisWeekRecordsCount > 0 { sectionsCount += 1 }
    if self.proxy.erlierRecordsCount > 0 { sectionsCount += 1 }
    return sectionsCount
  }
  
  private func doGetRowsCountForSection(section: Int) -> Int {
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
  
  private func doGetSectionHeaderTitle(section: Int) -> String {
    let category = decodeRecordCategoryForSection(section)
    switch category {
    case .Today: return "Today"
    case .ThisWeek: return "This Week"
    case .Erlier: return "Erlier"
    }
  }
  
  // MARK: - Notification Helpers
  private func notifySectionCreated(sectionIndex: Int) {
    if self.delegate != nil {
      self.delegate?.sectionCreated(sectionIndex)
    }
  }
  
  private func notifySectionDestroyed(sectionIndex: Int) {
    if self.delegate != nil {
      self.delegate?.sectionDestroyed(sectionIndex)
    }
  }
  
  private func notifyRowDeleted(section: Int, row: Int, lastRecord: Bool) {
    if self.delegate != nil {
      self.delegate?.rowDeleted(section, row: row, lastRecord: lastRecord)
    }
  }
  
  private func notifyRowInserted(section: Int, row: Int) {
    if self.delegate != nil {
      self.delegate?.rowInserted(section, row: row)
    }
  }
  private func notifyRowUpdated(section: Int, row: Int) {
    if self.delegate != nil {
      self.delegate?.rowUpdated(section, row: row)
    }
  }
}

