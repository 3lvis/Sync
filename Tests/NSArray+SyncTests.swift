import XCTest

class NSArray_SyncTests: XCTestCase {
  // Bug 125 => https://github.com/hyperoslo/Sync/issues/125

  /*func testPreprocessForEntityNamed() {
    let formDictionary = Helper.objectsFromJSON("bug-125-light.json") as! [String : NSObject]
    let uri = formDictionary["uri"] as! String
    let dataStack = Helper.dataStack("Bug125")

    let preprocessed = ([formDictionary] as NSArray).preprocessForEntityNamed("Form", predicate: Predicate(format: "uri = %@", uri), parent: nil, dataStack: dataStack).first!  as! [String : NSObject]
    XCTAssertEqual(preprocessed, formDictionary)
  }*/
}
