import CoreData
import XCTest


class FillWithDictionaryTests: XCTestCase {

    func testBug112() {
        let dataStack = Helper.dataStackWithModelName("112")

        let owner = Helper.insertEntity("Owner", dataStack: dataStack)
        owner.setValue(1, forKey: "id")

        let taskList = Helper.insertEntity("TaskList", dataStack: dataStack)
        taskList.setValue(1, forKey: "id")
        taskList.setValue(owner, forKey: "owner")

        let task = Helper.insertEntity("Task", dataStack: dataStack)
        task.setValue(1, forKey: "id")
        task.setValue(taskList, forKey: "taskList")
        task.setValue(owner, forKey: "owner")

        try! dataStack.mainContext.save()

        let ownerBody = [
            "id": 1,
            ] as [String: Any]
        let taskBoby = [
            "id": 1,
            "owner": ownerBody,
            ] as [String: Any]
        let expected = [
            "id": 1,
            "owner": ownerBody,
            "tasks": [taskBoby],
            ] as [String: Any]

        XCTAssertEqual(expected as NSDictionary, taskList.hyp_dictionary(using: .array) as NSDictionary)

        dataStack.drop()
    }

    func testBug121() {
        let dataStack = Helper.dataStackWithModelName("121")

        let album = Helper.insertEntity("Album", dataStack: dataStack)
        let json = [
            "id": "a",
            "coverPhoto": ["id": "b"],
            ] as [String: Any]
        album.hyp_fill(with: json)

        XCTAssertNotNil(album.value(forKey: "coverPhoto"))

        dataStack.drop()
    }

    func testBug123() {
        let dataStack = Helper.dataStackWithModelName("123")
        let user = Helper.insertEntity("User", dataStack: dataStack)
        user.setValue(1, forKey: "id")
        user.setValue("Ignore me", forKey: "name")

        try! dataStack.mainContext.save()
        let expected = [
            "id": 1,
            ] as [String: Any]

        XCTAssertEqual(expected as NSDictionary, user.hyp_dictionary(using: .none) as NSDictionary)

        dataStack.drop()
    }

    func testBug129() {
        ValueTransformer.setValueTransformer(BadAPIValueTransformer(), forName: NSValueTransformerName(rawValue: "BadAPIValueTransformer"))

        let dataStack = Helper.dataStackWithModelName("129")

        let user = Helper.insertEntity("User", dataStack: dataStack)
        let json = [
            "name": ["bad-backend-dev"],
            ] as [String: Any]
        user.hyp_fill(with: json)
        
        XCTAssertEqual(user.value(forKey: "name") as? String, "bad-backend-dev")
        
        dataStack.drop()
    }
}
