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

