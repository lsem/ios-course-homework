//////////////////////////////////////////////////////////////
// Some thoughts while I have no XCode installed (THIS SHOULD NOT BE COMPILABLE, IT IS SCRATCH!)
//////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////////////
//  Створити в цьому файлі клас на Swift, який представляє запис в щоденнику (припустимо, що ми пишемо аппу-щоденник) 
// і має приблизно такий інтерфейс:
// - дата створення, типу NSDate, встановлюється при створенні запису і ніколи не
// змінюється
// - назва, типу String, може бути відсутня
// - текст, типу String, може бути відсутній
// - теги, може бути декілька, може не бути жодного, кожен з тегів String
// - функція fullDescription(), повертає String, який містить вищезгадані властивості
// всі разом, і відформатовано таким чином, що кожна властивість на окремому рядку, а кожен з тегів в квадратних дужках
///////////////////////////////////////////////////////////////////////////////////////////////


// My thoughts about such class design. For enterprise code, probably, better design would be to make it plain POC
// and incorporate separate DiaryRecord formatter class which would be responsible for formatting and nothing more. 
// This class then would become DiaryRecordViewModel. This about applying of Single Responsibility Principle rule (from S.O.L.I.D). 
// Please note, I'm not trying to criticize design proposed for homework, but rather demonstrate my design skills.  
// P.S.: If it would be POC, then it should definitely be struct. 
class DiaryRecord {
	let creationDate: NSDate
	var recordName = ""
	var text = ""
	var tags: [String] = []

	init() {
		self.creationDate = NSDate.now()		// TODO: Find out how to get current data in Swift
		
		// While I have not feel good the language, it would be my first instinct in wiring initializers
		// to always initialize **all** fields/properties of the class.
		self.recordName = ""
		self.text = ""
		self.tags = []
	}

	/////////////////////////////////////////////
	// TODO: Add more descriptive initializers here
	/////////////////////////////////////////////

	// TODO: Clarify requirement about date formatting. It probably should be some kind of localized 
	// output but because of my laziness I did not do that.
	func fullDescription() -> String {
		return "\(self.creationDate)\n" +	// Hm, Swift does not have multi-line comments, but I still want to format such things in such a manner.
			"\(self.recordName)\n" +
			"\(self.text)\n" +
			"\(getFormattedTags())\n";
	}

	// TODO: Take a look at solution which cannot mutate neither string passed in parameter nor
	// own state. Do not also forget about default copy-by-value semantics for string copying. 
	func getFormattedTags() {
		// TODO: Consider using Join method
		var result_accumulator = ""
		for tag in self.tags {
			result_accumulator += "[\(tag)] "; 
		}
		return result_accumulator
	}
}


// Lets play with this

let record = DiaryRecord()

// Test default initializer
// NOTE: Pf, there is possibility to create record in the end of the day (say 23:59:00), then swapped from CPU, then resumed again
// in next day and then this test will be incorrect. So that, please ignore it if fails here at the end of the day :-)
assert(record.creationData == Date.now(), "Newly created record should have properly set creation date")

// Test all initializers
// ..

// Test modifiers (mutability, unintentional copying, etc..)
// ..

// Test formatting (using regular expressions?)
// ..


