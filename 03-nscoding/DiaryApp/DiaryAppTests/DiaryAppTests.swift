//
//  DiaryAppTests.swift
//  DiaryAppTests
//
//  Created by Lyubomyr Semkiv on 9/20/15.
//  Copyright © 2015 Lyubomyr Semkiv. All rights reserved.
//

import XCTest
import Foundation
import UIKit

@testable import DiaryApp

class DiaryAppTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    self.continueAfterFailure = false
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
    SystemKeyArchiverUnarchiverRepository(forTests: true).purgeAllData()
  }
  
  func test_Encoded_And_Decoded_DiaryRecord_Should_Be_Identical_To_Original() {
    let originalRecord = DiaryRecord(name: "Hapiness Record", text: "I'm just fool!", mood: RecordMood.Good)
    
    let encodedData: NSData? = NSKeyedArchiver.archivedDataWithRootObject(originalRecord)
    XCTAssert(encodedData != nil, "Failed archiving the record")
    
    let decodedRecord = NSKeyedUnarchiver.unarchiveObjectWithData(encodedData!) as? DiaryRecord
    XCTAssert(decodedRecord != nil, "Failed unarchiving the record")
    
    XCTAssert(originalRecord.name == decodedRecord!.name, "Mismatch in name field")
    XCTAssert(originalRecord.text == decodedRecord!.text, "Mismatch in text field")
    XCTAssert(originalRecord.mood == decodedRecord!.mood, "Mismatch in mood field")
    XCTAssert(originalRecord.creationDate == decodedRecord!.creationDate, "Mismatch in creationDate field")
  }
  
  func test_Encoded_And_Decoded_DiaryRecord_With_FileSystem_Storing_Should_Be_Identical_To_Original() {
    let originalRecord = DiaryRecord(name: "Hapiness Record", text: "I'm just fool!", mood: RecordMood.Good)
    
    let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
                  NSSearchPathDomainMask.UserDomainMask, true)
    assert(!paths.isEmpty)
    let documentsPath = paths[0]
    let documentsPathNSString = NSString(string: documentsPath)
    let finalStorePath = documentsPathNSString.stringByAppendingPathComponent("testDiaryRecord.archive")
    
    NSKeyedArchiver.archiveRootObject(originalRecord, toFile: finalStorePath)
    let loadedRecord = NSKeyedUnarchiver.unarchiveObjectWithFile(finalStorePath) as? DiaryRecord
    
    XCTAssert(loadedRecord != nil, "Failed loading and unarchiving the record")
    
    XCTAssert(originalRecord.name == loadedRecord!.name, "Mismatch in name field")
    XCTAssert(originalRecord.text == loadedRecord!.text, "Mismatch in text field")
    XCTAssert(originalRecord.mood == loadedRecord!.mood, "Mismatch in mood field")
    XCTAssert(originalRecord.creationDate == loadedRecord!.creationDate, "Mismatch in creationDate field")
  }
  
  func test_Coding_And_Decoding_Array_Of_DiaryRecords_To_FileSystem_Should_Work() {
    let dayRecords: [DiaryRecord] = [
      DiaryRecord(name: "Hapiness", text: "I'm just fool!", mood: RecordMood.Good),
      DiaryRecord(name: "Suffering", text: "Life is shit.", mood: RecordMood.Bad),
      DiaryRecord(name: "Dont Giving a Fuck", text: "Jah!!", mood: RecordMood.NoSet),
      DiaryRecord(name: "Like a Buddha", text: "Purity or impurity depends on oneself, No one can purify another.",
          mood: RecordMood.Neutral)
    ]

    let encodedArrayData: NSData? = NSKeyedArchiver.archivedDataWithRootObject(dayRecords)
    XCTAssert(encodedArrayData != nil, "Failed archiving the records array")
    let decodedRecordsArray = NSKeyedUnarchiver.unarchiveObjectWithData(encodedArrayData!) as? [DiaryRecord]
    XCTAssert(decodedRecordsArray != nil, "Failed unarchiving the record")
    
    for var idx = 0; idx < dayRecords.count; ++idx {
      let originalRecord = dayRecords[idx]
      let loadedRecord = decodedRecordsArray![idx]
      XCTAssert(originalRecord.name == loadedRecord.name, "Mismatch in name field for record \(idx)")
      XCTAssert(originalRecord.text == loadedRecord.text, "Mismatch in text field for record \(idx)")
      XCTAssert(originalRecord.mood == loadedRecord.mood, "Mismatch in mood field for record \(idx)")
      XCTAssert(originalRecord.creationDate == loadedRecord.creationDate, "Mismatch in creationDate field for record \(idx)")
    }
  }
  
  func test_Storing_And_Loading_Array_Of_DiaryRecords_To_FileSystem_Should_Work() {
    // TODO: Introduce something like forAllRepositories( code ) to test all repositories
    let repositories: [IDiaryRecordsRepository] = [
      SystemKeyArchiverUnarchiverRepository(forTests: true),
//      ICloudRepository()
    ]
    let records: [DiaryRecord] = [
      DiaryRecord(name: "Hapiness", text: "I'm just fool!", mood: RecordMood.Good),
      DiaryRecord(name: "Suffering", text: "Life is shit.", mood: RecordMood.Bad)
    ]

    for repository in repositories {
      XCTAssert(repository.storeDiaryRecordCollection(records))
      let loadedRecords  = repository.loadDiaryRecordCollection()
      XCTAssert(loadedRecords != nil, "Failed loading diaries collection for repository \(loadedRecords.dynamicType)")
      XCTAssert(loadedRecords!.count == records.count, "Loaded, but not enough")
      for var ridx = 0; ridx < records.count; ++ridx {
        let originalRecord = records[ridx]
        let loadedRecord = loadedRecords![ridx]
        assertAreRecordsEqual(originalRecord: originalRecord, loadedRecord: loadedRecord, recordName: "\(ridx)")
      }
    }
  }
  
  func assertAreRecordsEqual(originalRecord originalRecord: DiaryRecord, loadedRecord: DiaryRecord, recordName: String) {
    XCTAssert(originalRecord.name == loadedRecord.name, "Mismatch in name field for record " + recordName)
    XCTAssert(originalRecord.text == loadedRecord.text, "Mismatch in text field for record " + recordName)
    XCTAssert(originalRecord.mood == loadedRecord.mood, "Mismatch in mood field for record " + recordName)
    XCTAssert(originalRecord.creationDate == loadedRecord.creationDate, "Mismatch in creationDate field for record " + recordName)
  }

  // TODO: Verify it can store and load a lot of data, say 1_000_000 records
  // TODO: Verify it can load/store one by one, to catch bugs caused by some kind of statefull internal model
  
  func test_Storing_And_Loading_Via_Abstract_Persistance_Subsystem_Should_Work() {
    // ...
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measureBlock {
      // Put the code you want to measure the time of here.
    }
  }
}
