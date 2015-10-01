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
  func purgeAllData()
}

////////////////////////////////////////////////////////////
// TODO: Make Error Handling
// Repository for persisting application data to local filesystem
class SystemKeyArchiverUnarchiverRepository : IDiaryRecordsRepository {
  private var storeFileFileSystemPath: String = SystemKeyArchiverUnarchiverRepository.allRecordsCollectionFilePath()

  // The parameter forTests is an ad-hoc solution to adress the problem
  // that after renunning unit tests, data written during the test is left.
  // In testing mode alternative data file is which also is deleted at test end.
  init(forTests testingMode: Bool = false) {
    if testingMode {
        self.storeFileFileSystemPath = SystemKeyArchiverUnarchiverRepository.allRecordsCollectionFileTestsPath()
    } else {
        self.storeFileFileSystemPath = SystemKeyArchiverUnarchiverRepository.allRecordsCollectionFilePath()
    }
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
        toFile: self.storeFileFileSystemPath)
    return result
  }
  
  func loadDiaryRecordCollection() -> [DiaryRecord]? {
    let loadedRecords = NSKeyedUnarchiver.unarchiveObjectWithFile(
        self.storeFileFileSystemPath) as? [DiaryRecord]
    return loadedRecords
  }
  
  func purgeAllData() {
    let fileManaeger = NSFileManager.defaultManager()
    do {
      try fileManaeger.removeItemAtPath(self.storeFileFileSystemPath)
    } catch _ {
      NSLog("ERROR: Failed removing data file")
    }
  }
  
  // MARK: - Private
  
  private static func getDocumentsDirectoryPath() -> String {
    let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
      NSSearchPathDomainMask.UserDomainMask, true)
    assert(!paths.isEmpty)
    let documentsPath = paths.first!
    return documentsPath
  }
  
  private static func allRecordsCollectionFilePath() -> String {
    let docsPathNS = NSString(string: SystemKeyArchiverUnarchiverRepository.getDocumentsDirectoryPath())
    let completePath = docsPathNS.stringByAppendingPathComponent("allDiaryRecordsCollection.archive")
    return completePath
  }
  
  private static func allRecordsCollectionFileTestsPath() -> String {
    let docsPathNS = NSString(string: SystemKeyArchiverUnarchiverRepository.getDocumentsDirectoryPath())
    let completePath = docsPathNS.stringByAppendingPathComponent("allDiaryRecordsCollection_tests.archive")
    return completePath
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
  
  func purgeAllData() {
    assert(false, "Not implemented")
  }
}
