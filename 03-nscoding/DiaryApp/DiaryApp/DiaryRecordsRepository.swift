//
//  DiaryRecordsRepository.swift
//  	
//
//  Created by Lyubomyr Semkiv on 9/22/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import Foundation


// Service responsible for storing/loading diary records.
protocol IDiaryRecordsRepository {
  func storeDiaryRecord(record: DiaryRecord)
  func loadDiaryRecord() -> DiaryRecord
  func storeDiaryRecordCollection(records: [DiaryRecord]) -> Bool
  func loadDiaryRecordCollection() -> [DiaryRecord]?
}


////////////////////////////////////////////////////////////
// TODO: Make Error Handling
// Repository for persisting application data to local filesystem
class SystemKeyArchiverUnarchiverRepository : IDiaryRecordsRepository {
  static let StoreFileFileSystemPath: String = SystemKeyArchiverUnarchiverRepository.allRecordsCollectionFilePath()

  static func getDocumentsDirectoryPath() -> String {
    let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
      NSSearchPathDomainMask.UserDomainMask, true)
    assert(!paths.isEmpty)
    let documentsPath = paths[0]
    return documentsPath
  }

  static func allRecordsCollectionFilePath() -> String {
    let docsPathNS = NSString(string: SystemKeyArchiverUnarchiverRepository.getDocumentsDirectoryPath())
    let completePath = docsPathNS.stringByAppendingPathComponent("allDiaryRecordsCollection.archive")
    return completePath
  }

  func storeDiaryRecord(record: DiaryRecord) {
    assert(false, "Not implemented")
  }
  
  func loadDiaryRecord() -> DiaryRecord {
    assert(false, "Not implemented")
    return DiaryRecord()
  }
  
  func storeDiaryRecordCollection(records: [DiaryRecord]) -> Bool {
    let result = NSKeyedArchiver.archiveRootObject(records,
        toFile: SystemKeyArchiverUnarchiverRepository.StoreFileFileSystemPath)
    return result
  }
  
  func loadDiaryRecordCollection() -> [DiaryRecord]? {
    let loadedRecords = NSKeyedUnarchiver.unarchiveObjectWithFile(
        SystemKeyArchiverUnarchiverRepository.StoreFileFileSystemPath) as? [DiaryRecord]
    return loadedRecords
  }
}

////////////////////////////////////////////////////////////
// Repository for persising application data to in ICloud
class ICloudRepository : IDiaryRecordsRepository {
  func storeDiaryRecord(record: DiaryRecord) {
    assert(false, "Not implemented")
  }
  
  func loadDiaryRecord() -> DiaryRecord {
    assert(false, "Not implemented")
    return DiaryRecord()
  }
  
  func storeDiaryRecordCollection(records: [DiaryRecord]) -> Bool {
    assert(false, "Not implemented")
    return false
  }
  
  func loadDiaryRecordCollection() -> [DiaryRecord]? {
    assert(false, "Not implemented")
    return [DiaryRecord]()
  }
}
