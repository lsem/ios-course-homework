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
  var repositories: [IDiaryRecordsRepository] = []
  
  override func setUp() {
    super.setUp()
    self.continueAfterFailure = false
    SystemKeyArchiverUnarchiverRepository(forTests: true).purgeAllData()
    self.repositories = [
      SystemKeyArchiverUnarchiverRepository(forTests: true),
      //      ICloudRepository()
    ]
    
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
    let records: [DiaryRecord] = [
      DiaryRecord(name: "Hapiness", text: "I'm just fool!", mood: RecordMood.Good),
      DiaryRecord(name: "Suffering", text: "Life is shit.", mood: RecordMood.Bad)
    ]

    for repository in self.repositories {
      XCTAssert(repository.storeDiaryRecordCollection(records))
      let loadedRecords  = repository.loadDiaryRecordCollection()
      XCTAssert(loadedRecords != nil, "Failed loading diaries collection for repository \(repository.dynamicType)")
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

  func test_Application_Can_Store_Lot_Of_Data() {
    let sampleRecord = DiaryRecord(name: "Hapiness", text: "I'm just fool!", mood: RecordMood.Good)

    let aLotOfrecords = [DiaryRecord](count: (24*365*10), repeatedValue: sampleRecord)
    for repository in self.repositories {
      XCTAssertTrue(repository.storeDiaryRecordCollection(aLotOfrecords),
        "Failed to store records for repository \(repository.dynamicType)")
      let loadedData = repository.loadDiaryRecordCollection()
      XCTAssert(loadedData != nil, "Failed to load previosuly saved data")
      XCTAssertTrue(loadedData!.count == aLotOfrecords.count, "An amount of data loaded is less then was stored")
      for (index, diaryRecord) in loadedData!.enumerate() {
        let originalRecord = aLotOfrecords[index]
        let restoredRecord = diaryRecord
        assertAreRecordsEqual(originalRecord: originalRecord, loadedRecord: restoredRecord, recordName: "\(index)")
      }
    }
  }
  
  func test_ApplicationSettings_Can_Be_Saved_And_Resotred_From_DefaultsStorage() {
    let appSettings = ApplicationSettings()
    appSettings.naturalLanguageSupport = true
    appSettings.showTimeAndDate = true
    let appSettingsData: NSData? = NSKeyedArchiver.archivedDataWithRootObject(appSettings)
    XCTAssert(appSettingsData != nil, "Failed to encode data")
    NSUserDefaults.standardUserDefaults().setObject(appSettingsData, forKey: "appSettings")
    let resotoredSettingsData: NSData? = NSUserDefaults.standardUserDefaults().objectForKey("appSettings") as? NSData
    XCTAssert(resotoredSettingsData != nil, "Failed to restore data")
    let restoredSettingsObject: ApplicationSettings? = NSKeyedUnarchiver.unarchiveObjectWithData(resotoredSettingsData!) as? ApplicationSettings
    XCTAssert(restoredSettingsObject != nil, "Failed to decode restored data")
    XCTAssert(restoredSettingsObject!.naturalLanguageSupport == true, "Mismatch in naturalLanguageSupport")
    XCTAssert(restoredSettingsObject!.showTimeAndDate == true, "Mismatch in naturalLanguageSupport")
  }
  
  // MARK: - Data Model Tests
  
  func test_Basic_DataModel_Functionality_Should_Work() {
    let dataModel = DataModel()
    
    // Make two passes to make sure after add-remove cycle it still works.
    var passesLeft = 2
    while (passesLeft-- != 0) {
      XCTAssert(dataModel.retrieveAllDiaryRecords().count == 0)
      XCTAssert(dataModel.recordsCount == 0)
      
      let sundayRecordId = dataModel.addDiaryRecord(DiaryRecord(name: "Sunday", text: "Good day", mood: RecordMood.Good))
      
      XCTAssert(dataModel.recordsCount == 1)

      // TODO: Make it separete test with descriptive name
      // Verify getting data working and it is not destructive
      XCTAssert(dataModel.retrieveAllDiaryRecordValues().count == 1)
      XCTAssert(dataModel.retrieveAllDiaryRecordValues().count == 1)
      XCTAssert(dataModel.retrieveAllDiaryRecordValues()[0].name == "Sunday")
      XCTAssert(dataModel.retrieveAllDiaryRecordValues()[0].text == "Good day")
      XCTAssert(dataModel.retrieveAllDiaryRecordValues()[0].mood == RecordMood.Good)
     
      // TODO: Make it separete test with descriptive name
      // Verify removing data working
      dataModel.removeDiaryRecordByID(sundayRecordId)
      XCTAssert(dataModel.recordsCount == 0)
      XCTAssert(dataModel.retrieveAllDiaryRecords().count == 0)
    }
  }
  
  func test_UIDataModel_Proxy_Date_Categorizing_Should_Work() {
    let dataModel = DataModel()
    XCTAssert(dataModel.recordsCount == 0)
    let dataModelProxy = DataModelUIProxy(dataModel: dataModel)
    
    // Check currently proxy does not return any data
    XCTAssert(dataModelProxy.retrieveErlierRecords().count == 0)
    XCTAssert(dataModelProxy.retrieveTheseWeekRecords().count == 0)
    XCTAssert(dataModelProxy.retrieveTodayRecords().count == 0)
    
    // Add some data to datamodel and verify proxy model knows about them
    dataModel.addDiaryRecord(DiaryRecord(name: "Sunday", text: "Good day", mood: RecordMood.Good))
    XCTAssert(dataModelProxy.retrieveErlierRecords().count == 0)
    XCTAssert(dataModelProxy.retrieveTheseWeekRecords().count == 0)
    XCTAssert(dataModelProxy.retrieveTodayRecords().count == 1)
    
    // And one more
    dataModel.addDiaryRecord(DiaryRecord(name: "Monday", text: "Again Good day", mood: RecordMood.Good))
    XCTAssert(dataModelProxy.retrieveErlierRecords().count == 0)
    XCTAssert(dataModelProxy.retrieveTheseWeekRecords().count == 0)
    XCTAssert(dataModelProxy.retrieveTodayRecords().count == 2)
    
    // And check also what it fact it returns
    XCTAssert(dataModelProxy.retrieveTodayRecords()[0].1.name == "Sunday")
    XCTAssert(dataModelProxy.retrieveTodayRecords()[1].1.name == "Monday")
  }
  
  static func dateWithDaysAdded(date: NSDate, days: Int) -> NSDate {
    let secondsTotal: NSTimeInterval = 60.0 * 60.0 * 24.0 * Double(days)
    return date.dateByAddingTimeInterval(secondsTotal)
  }
  
  static func dateWithHoursAdded(date: NSDate, hours: Int) -> NSDate {
    let secondsTotal: NSTimeInterval = 60.0 * 60.0 * Double(hours)
    return date.dateByAddingTimeInterval(secondsTotal)
  }

  static func dateWithSecondsAdded(date: NSDate, seconds: Int) -> NSDate {
    let secondsTotal: NSTimeInterval = Double(seconds)
    return date.dateByAddingTimeInterval(secondsTotal)
  }
  
  
  func test_DataModelProxy_Should_Update_Itself_Correctly_After_DataModel_Records_Update_Delete_Insert() {
    let dataModel = DataModel()
    XCTAssert(dataModel.recordsCount == 0)
    let dataModelProxy = DataModelUIProxy(dataModel: dataModel)

    // Make all tests two passes on the same instance to verify it can work properly after full usage cycle
    var passesLeft = 2
    while passesLeft-- != 0 {
      
      let sundayRecordId = dataModel.addDiaryRecord(DiaryRecord(name: "Sunday", text: "Good day", mood: RecordMood.Good))
      let mondayRecordId = dataModel.addDiaryRecord(DiaryRecord(name: "Monday", text: "Another Good day", mood: RecordMood.Good))

      XCTAssert(dataModelProxy.retrieveErlierRecords().count == 0)
      XCTAssert(dataModelProxy.retrieveTheseWeekRecords().count == 0)
      XCTAssert(dataModelProxy.retrieveTodayRecords().count == 2)
      XCTAssert(dataModelProxy.retrieveAllRecordsSortedByCreationDate().count == 2)
      let dateOrderedIndex = dataModelProxy.retrieveAllRecordsSortedByCreationDate()
      XCTAssert(dataModelProxy.retrieveTodayRecords()[0].1.name == "Sunday")
      XCTAssert(dataModelProxy.retrieveTodayRecords()[1].1.name == "Monday")
      XCTAssert(dateOrderedIndex[0].name == "Sunday")
      XCTAssert(dateOrderedIndex[1].name == "Monday")
      
      // Lets change record date to some erlier equialent (more then 7 days back)
      dataModel.updateDiaryRecorByID(mondayRecordId) { (record: DiaryRecord) in
        record.creationDate = DiaryAppTests.dateWithDaysAdded(record.creationDate, days: -10)
      };

      XCTAssert(dataModelProxy.retrieveErlierRecords().count == 1)
      XCTAssert(dataModelProxy.retrieveTheseWeekRecords().count == 0)
      XCTAssert(dataModelProxy.retrieveTodayRecords().count == 1)
      let sorted = dataModelProxy.retrieveAllRecordsSortedByCreationDate()
      XCTAssert(sorted.count == 2)
      let dateOrderedIndexAftedUpdated = dataModelProxy.retrieveAllRecordsSortedByCreationDate()
      XCTAssert(dataModelProxy.retrieveTodayRecords()[0].1.name == "Sunday")
      XCTAssert(dataModelProxy.retrieveErlierRecords()[0].1.name == "Monday")
      XCTAssert(dateOrderedIndexAftedUpdated[0].name == "Monday")
      XCTAssert(dateOrderedIndexAftedUpdated[1].name == "Sunday")

      // Lets change record date to some erlier equialent (more then 7 days back)
      dataModel.updateDiaryRecorByID(mondayRecordId) { (record: DiaryRecord) in
        record.creationDate = DiaryAppTests.dateWithDaysAdded(record.creationDate, days: +10)
      };
      
      XCTAssert(dataModelProxy.retrieveErlierRecords().count == 0)
      XCTAssert(dataModelProxy.retrieveTheseWeekRecords().count == 0)
      XCTAssert(dataModelProxy.retrieveTodayRecords().count == 2)
      XCTAssert(dataModelProxy.retrieveAllRecordsSortedByCreationDate().count == 2)
      let dateOrderedIndexAftertTwoUpdates = dataModelProxy.retrieveAllRecordsSortedByCreationDate()
      XCTAssert(dataModelProxy.retrieveTodayRecords()[0].1.name == "Sunday")
      XCTAssert(dataModelProxy.retrieveTodayRecords()[1].1.name == "Monday")
      XCTAssert(dateOrderedIndexAftertTwoUpdates[0].name == "Sunday")
      XCTAssert(dateOrderedIndexAftertTwoUpdates[1].name == "Monday")
      

      // Remove test
      dataModel.removeDiaryRecordByID(sundayRecordId) // remove Sunday's record
      XCTAssert(dataModelProxy.retrieveErlierRecords().count == 0)
      XCTAssert(dataModelProxy.retrieveTheseWeekRecords().count == 0)
      XCTAssert(dataModelProxy.retrieveTodayRecords().count == 1)
      XCTAssert(dataModelProxy.retrieveAllRecordsSortedByCreationDate().count == 1)
      let dateOrderedIndexAftertRemove = dataModelProxy.retrieveAllRecordsSortedByCreationDate()
      XCTAssert(dataModelProxy.retrieveTodayRecords()[0].1.name == "Monday")
      XCTAssert(dateOrderedIndexAftertRemove[0].name == "Monday")
      // Remove latest
      dataModel.removeDiaryRecordByID(mondayRecordId) // remove Mondays record
      XCTAssert(dataModelProxy.retrieveErlierRecords().count == 0)
      XCTAssert(dataModelProxy.retrieveTheseWeekRecords().count == 0)
      XCTAssert(dataModelProxy.retrieveTodayRecords().count == 0)
      XCTAssert(dataModelProxy.retrieveAllRecordsSortedByCreationDate().count == 0)
    }
  }
  
  func test_Queries_To_Proxy_Model_For_Model_Data_Indices_Should_Work_Correctly() {
    let dataModel = DataModel()
    XCTAssert(dataModel.recordsCount == 0)
    let dataModelProxy = DataModelUIProxy(dataModel: dataModel)
    
    dataModel.addDiaryRecord(DiaryRecord(name: "Sunday", text: "Good day", mood: RecordMood.Good))
    dataModel.addDiaryRecord(DiaryRecord(name: "Monday", text: "Another Good day", mood: RecordMood.Good))
    
    XCTAssert(dataModelProxy.getModelRecordIdByTodayRecordIndex(0) == 0)
    XCTAssert(dataModelProxy.getModelRecordIdByTodayRecordIndex(1) == 1)

    // After this monday should left todays group but data index should be the same
    dataModel.updateDiaryRecorByID(1) { (record: DiaryRecord) in
      record.creationDate = DiaryAppTests.dateWithDaysAdded(record.creationDate, days: -10)
    };

    XCTAssert(dataModelProxy.getModelRecordIdByTodayRecordIndex(0) == 0)
    XCTAssert(dataModelProxy.getModelRecordIdByErlierRecordIndex(0) == 1)
    
  }
  
  func test_Mood_Categorization_By_Proxy_Model_Should_Work() {
    let dataModel = DataModel()
    XCTAssert(dataModel.recordsCount == 0)
    let dataModelProxy = DataModelUIProxy(dataModel: dataModel)
    
    dataModel.addDiaryRecord(DiaryRecord(name: "Sunday", text: "Good day", mood: RecordMood.Good))
    dataModel.addDiaryRecord(DiaryRecord(name: "Monday", text: "Another Good day", mood: RecordMood.Good))
    
    XCTAssert(dataModelProxy.getRecordsCountForMood(.Good) == 2)
    XCTAssert(dataModelProxy.getRecordsCountForMood(.Bad) == 0)
    XCTAssert(dataModelProxy.getRecordsCountForMood(.NoSet) == 0)
    XCTAssert(dataModelProxy.getRecordsCountForMood(.Neutral) == 0)
    
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Good, index: 0).name == "Sunday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Good, index: 1).name == "Monday")

    dataModel.addDiaryRecord(DiaryRecord(name: "Tuesday", text: "Another Good day", mood: RecordMood.Bad))
    dataModel.addDiaryRecord(DiaryRecord(name: "Wednesday", text: "Another Good day", mood: RecordMood.Neutral))
    dataModel.addDiaryRecord(DiaryRecord(name: "Thursday", text: "Another Good day", mood: RecordMood.Neutral))

    XCTAssert(dataModelProxy.getRecordsCountForMood(.Good) == 2)
    XCTAssert(dataModelProxy.getRecordsCountForMood(.Bad) == 1)
    XCTAssert(dataModelProxy.getRecordsCountForMood(.NoSet) == 0)
    XCTAssert(dataModelProxy.getRecordsCountForMood(.Neutral) == 2)
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Good, index: 0).name == "Sunday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Good, index: 1).name == "Monday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Bad, index: 0).name == "Tuesday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Neutral, index: 0).name == "Wednesday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Neutral, index: 1).name == "Thursday")
    
    dataModel.addDiaryRecord(DiaryRecord(name: "Friday", text: "Another Good day", mood: RecordMood.NoSet))

    XCTAssert(dataModelProxy.getRecordsCountForMood(.Good) == 2)
    XCTAssert(dataModelProxy.getRecordsCountForMood(.Bad) == 1)
    XCTAssert(dataModelProxy.getRecordsCountForMood(.NoSet) == 1)
    XCTAssert(dataModelProxy.getRecordsCountForMood(.Neutral) == 2)
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Good, index: 0).name == "Sunday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Good, index: 1).name == "Monday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Bad, index: 0).name == "Tuesday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Neutral, index: 0).name == "Wednesday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Neutral, index: 1).name == "Thursday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.NoSet, index: 0).name == "Friday")
    
    // Lets remove all neutral records
    let count = dataModelProxy.getRecordsCountForMood(.Neutral)
    XCTAssert(count == 2)
    for _ in 0..<count {
      let modelId = dataModelProxy.getModelRecordByMoodOrderedIndex(.Neutral, index: 0)
      NSLog("removing : \(modelId)")
      dataModel.removeDiaryRecordByID(modelId)
    }
    // And insert one
    dataModel.addDiaryRecord(DiaryRecord(name: "Saturday", text: "Another Good day", mood: RecordMood.NoSet))
    // And update one
    let firstGoodRecordModelIndex = dataModelProxy.getModelRecordByMoodOrderedIndex(.Good, index: 0)
    dataModel.updateDiaryRecorByID(firstGoodRecordModelIndex) {
      $0.mood = RecordMood.Bad
    }

    XCTAssert(dataModelProxy.getRecordsCountForMood(.Good) == 1)
    XCTAssert(dataModelProxy.getRecordsCountForMood(.Bad) == 2)
    XCTAssert(dataModelProxy.getRecordsCountForMood(.NoSet) == 2)
    XCTAssert(dataModelProxy.getRecordsCountForMood(.Neutral) == 0)
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Good, index: 0).name == "Monday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Bad, index: 0).name == "Sunday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.Bad, index: 1).name == "Tuesday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.NoSet, index: 0).name == "Friday")
    XCTAssert(dataModelProxy.getMoodRecordAtIndexForMood(RecordMood.NoSet, index: 1).name == "Saturday")
  }
  
  enum ModelViewEvent {
    case SectionCreated(Int)
    case SectionDestroyed(Int)
    case RowDeleted(Int, Int)
    case RowInserted(Int, Int)
    case RowUpdated(Int, Int)
  }
  
  // Don't be a pussy, do mocking manually!
  class CreationDateCategorizationDataModelProxyMock : CreationDateCategorizationDataModelProxyDelegate {
    var events: [ModelViewEvent] = []
    var sectionsCreatedCount = 0
    var sectionsDestroyedCount = 0
    var rowsDeletedCount = 0
    var rowsInsetedCount = 0
    var rowsUpdatedCount = 0

    var sectionCreatedEventsArray_: [Int] = []
    var sectionRemovedEventsArray_: [Int] = []
    var rowsDeletedEventsArray_: [(Int, Int)] = []
    var rowsInsertedEventsArray_: [(Int, Int)] = []
    var rowsUpdatedEventsArray_: [(Int, Int)] = []

    var eventsCount: Int { get { return self.events.count } }
    
    var sectionCreatedEventsArray: [Int] { get { categorizeEvents(); return sectionCreatedEventsArray_ } }
    var sectionRemovedEventsArray: [Int]  { get { categorizeEvents(); return sectionRemovedEventsArray_ } }
    var rowsDeletedEventsArray: [(Int, Int)]  { get { categorizeEvents(); return rowsDeletedEventsArray_ } }
    var rowsInsertedEventsArray: [(Int, Int)]  { get { categorizeEvents(); return rowsInsertedEventsArray_ } }
    var rowsUpdatedEventsArray: [(Int, Int)]  { get { categorizeEvents(); return rowsUpdatedEventsArray_ } }
    
    func categorizeEvents() {
      self.sectionCreatedEventsArray_.removeAll()
      self.sectionRemovedEventsArray_.removeAll()
      self.rowsDeletedEventsArray_.removeAll()
      self.rowsInsertedEventsArray_.removeAll()
      self.rowsUpdatedEventsArray_.removeAll()
      for event in self.events {
        switch event {
        case let .SectionCreated(sectionIdx): self.sectionCreatedEventsArray_.append(sectionIdx)
        case let .SectionDestroyed(sectionIdx): self.sectionRemovedEventsArray_.append(sectionIdx)
        case let .RowDeleted(sectionIdx, rowIdx): self.rowsDeletedEventsArray_.append((sectionIdx, rowIdx))
        case let .RowInserted(sectionIdx, rowIdx): self.rowsInsertedEventsArray_.append((sectionIdx, rowIdx))
        case let .RowUpdated(sectionIdx, rowIdx): self.rowsUpdatedEventsArray_.append((sectionIdx, rowIdx))
        }
      }
    }
  
    func clearEvents() { events.removeAll() }
    
    func sectionCreated(sectionIndex: Int) -> Void {
      self.events.append(ModelViewEvent.SectionCreated(sectionIndex))
      self.sectionsCreatedCount += 1
    }
    
    func sectionDestroyed(sectionIndex: Int) -> Void {
      self.events.append(ModelViewEvent.SectionDestroyed(sectionIndex))
      self.sectionsDestroyedCount += 1
    }
    
    func rowDeleted(section: Int, row: Int, lastRecord: Bool) -> Void {
      self.events.append(ModelViewEvent.RowDeleted(section, row))
      self.rowsDeletedCount += 1
    }
    
    func rowInserted(section: Int, row: Int) -> Void {
      self.events.append(ModelViewEvent.RowInserted(section, row))
      self.rowsInsetedCount += 1
    }
    
    func rowUpdated(section: Int, row: Int) -> Void {
      self.events.append(ModelViewEvent.RowUpdated(section, row))
      self.rowsUpdatedCount += 1
    }
  }
  
  func test_TableView_Proxy_Should_Correctly_Handle_Manipulating_Data_Model() {
    let dataModel = DataModel()
    let tableViewProxy = DataModelProxiesFactory.getCreationDateCategorizationDataModelProxy(dataModel: dataModel)
    let proxyMock = CreationDateCategorizationDataModelProxyMock()
    tableViewProxy.delegate = proxyMock
    
    var passedLeft = 3
    while passedLeft-- != 0 {
      
      let wednesdayRecordId = dataModel.addDiaryRecord(DiaryRecord(name: "Wednesday", text: "", mood: RecordMood.Good))
      let thursdayDate = DiaryAppTests.dateWithSecondsAdded(NSDate(), seconds: +10)
      let thursdayRecordId = dataModel.addDiaryRecord(
        DiaryRecord(name: "Trhursday", text: "", mood: RecordMood.Good, creationDate: thursdayDate))
      
      XCTAssert(proxyMock.eventsCount == 3)
      XCTAssert(proxyMock.sectionCreatedEventsArray[0] == 0/*section idx*/)
      XCTAssert(proxyMock.rowsInsertedEventsArray[0].0 == 0 /*section idx*/)
      XCTAssert(proxyMock.rowsInsertedEventsArray[0].1 == 0 /*row idx*/)
      XCTAssert(proxyMock.rowsInsertedEventsArray[1].0 == 0 /*section idx*/)
      XCTAssert(proxyMock.rowsInsertedEventsArray[1].1 == 1 /*row idx*/)

      proxyMock.clearEvents()
      
      // Remove wednesday
      dataModel.removeDiaryRecordByID(wednesdayRecordId)

      XCTAssert(proxyMock.eventsCount == 1)
      XCTAssert(proxyMock.rowsDeletedEventsArray[0].0 == 0/*section idx*/)
      XCTAssert(proxyMock.rowsDeletedEventsArray[0].1 == 0/*row idx*/)
      
      proxyMock.clearEvents()
      
      dataModel.removeDiaryRecordByID(thursdayRecordId)
      
      XCTAssert(proxyMock.eventsCount == 2)
      XCTAssert(proxyMock.rowsDeletedEventsArray[0].0 == 0/*section idx*/)
      XCTAssert(proxyMock.rowsDeletedEventsArray[0].0 == 0/*row idx*/)
      XCTAssert(proxyMock.sectionRemovedEventsArray[0] == 0/*section idx*/)
      
      proxyMock.clearEvents()
    }
  }
  
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measureBlock {
      // Put the code you want to measure the time of here.
    }
  }
}
