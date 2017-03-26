import CoreData
import XCTest
import Sync

class DictionaryTests: XCTestCase {
    let sampleSnakeCaseJSON = [
        "description": "reserved",
        "inflection_binary_data": ["one", "two"],
        "inflection_date": "1970-01-01",
        "custom_remote_key": "randomRemoteKey",
        "inflection_id": 1,
        "inflection_string": "string",
        "inflection_integer": 1,
        "ignored_parameter": "ignored",
        "ignore_transformable": "string",
        ] as [String : Any]

    func testExportDictionaryWithSnakeCase() {
        // Fill in transformable attributes is not supported in Swift 3. Crashes when saving the context.
        let dataStack = Helper.dataStackWithModelName("137")
        let user = NSEntityDescription.insertNewObject(forEntityName: "InflectionUser", into: dataStack.mainContext)
        user.hyp_fill(with: self.sampleSnakeCaseJSON)
        try! dataStack.mainContext.save()

        let compared = [
            "description": "reserved",
            "inflection_binary_data": NSKeyedArchiver.archivedData(withRootObject: ["one", "two"]) as NSData,
            "inflection_date": "1970-01-01",
            "randomRemoteKey": "randomRemoteKey",
            "inflection_id": 1,
            "inflection_string": "string",
            "inflection_integer": 1
            ] as [String : Any]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "GMT")

        let result = user.hyp_dictionary(with: formatter, using: .snakeCase)

        for (key, value) in compared {
            if let comparedValue = result[key] {
                XCTAssertEqual(value as? NSObject, comparedValue as? NSObject)
            }
        }

        dataStack.drop()
    }

    func testExportDictionaryWithCamelCase() {
        // Fill in transformable attributes is not supported in Swift 3. Crashes when saving the context.
        let dataStack = Helper.dataStackWithModelName("137")
        let user = NSEntityDescription.insertNewObject(forEntityName: "InflectionUser", into: dataStack.mainContext)
        user.hyp_fill(with: self.sampleSnakeCaseJSON)
        try! dataStack.mainContext.save()

        let compared = [
            "description": "reserved",
            "inflectionBinaryData": NSKeyedArchiver.archivedData(withRootObject: ["one", "two"]) as NSData,
            "inflectionDate": "1970-01-01",
            "randomRemoteKey": "randomRemoteKey",
            "inflectionID": 1,
            "inflectionString": "string",
            "inflectionInteger": 1
            ] as [String : Any]

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "GMT")

        let result = user.hyp_dictionary(with: formatter, using: .camelCase)
        print(result)
        XCTAssertEqual(compared as NSDictionary, result as NSDictionary)

        dataStack.drop()
    }

    let sampleSnakeCaseJSONWithRelationship = ["inflection_id": 1] as [String : Any]

    func testExportDictionaryWithSnakeCaseRelationshipArray() {
        // Fill in transformable attributes is not supported in Swift 3. Crashes when saving the context.
        let dataStack = Helper.dataStackWithModelName("137")
        let user = NSEntityDescription.insertNewObject(forEntityName: "InflectionUser", into: dataStack.mainContext)
        user.hyp_fill(with: self.sampleSnakeCaseJSONWithRelationship)

        let company = NSEntityDescription.insertNewObject(forEntityName: "InflectionCompany", into: dataStack.mainContext)
        company.setValue(NSNumber(value: 1), forKey: "inflectionID")
        user.setValue(company, forKey: "camelCaseCompany")

        try! dataStack.mainContext.save()

        let compared = [
            "inflection_binary_data": NSNull(),
            "inflection_date": NSNull(),
            "inflection_id": 1,
            "inflection_integer": NSNull(),
            "inflection_string": NSNull(),
            "randomRemoteKey": NSNull(),
            "description": NSNull(),
            "camel_case_company": [
                "inflection_id": 1
            ]
            ] as [String : Any]

        let result = user.hyp_dictionary(using: .snakeCase, andRelationshipType: .array)
        print(result)
        XCTAssertEqual(compared as NSDictionary, result as NSDictionary)

        dataStack.drop()
    }

    func testExportDictionaryWithCamelCaseRelationshipArray() {
        // Fill in transformable attributes is not supported in Swift 3. Crashes when saving the context.
        let dataStack = Helper.dataStackWithModelName("137")
        let user = NSEntityDescription.insertNewObject(forEntityName: "InflectionUser", into: dataStack.mainContext)
        user.hyp_fill(with: self.sampleSnakeCaseJSONWithRelationship)

        let company = NSEntityDescription.insertNewObject(forEntityName: "InflectionCompany", into: dataStack.mainContext)
        company.setValue(NSNumber(value: 1), forKey: "inflectionID")
        user.setValue(company, forKey: "camelCaseCompany")

        try! dataStack.mainContext.save()

        let compared = [
            "inflectionBinaryData": NSNull(),
            "inflectionDate": NSNull(),
            "inflectionID": 1,
            "inflectionInteger": NSNull(),
            "inflectionString": NSNull(),
            "randomRemoteKey": NSNull(),
            "description": NSNull(),
            "camelCaseCompany": [
                "inflectionID": 1
            ]
            ] as [String : Any]

        let result = user.hyp_dictionary(using: .camelCase, andRelationshipType: .array)
        print(result)
        XCTAssertEqual(compared as NSDictionary, result as NSDictionary)

        dataStack.drop()
    }

    func testExportDictionaryWithSnakeCaseRelationshipNested() {
        // Fill in transformable attributes is not supported in Swift 3. Crashes when saving the context.
        let dataStack = Helper.dataStackWithModelName("137")
        let user = NSEntityDescription.insertNewObject(forEntityName: "InflectionUser", into: dataStack.mainContext)
        user.hyp_fill(with: self.sampleSnakeCaseJSONWithRelationship)

        let company = NSEntityDescription.insertNewObject(forEntityName: "InflectionCompany", into: dataStack.mainContext)
        company.setValue(NSNumber(value: 1), forKey: "inflectionID")
        user.setValue(company, forKey: "camelCaseCompany")

        try! dataStack.mainContext.save()

        let compared = [
            "inflection_binary_data": NSNull(),
            "inflection_date": NSNull(),
            "inflection_id": 1,
            "inflection_integer": NSNull(),
            "inflection_string": NSNull(),
            "randomRemoteKey": NSNull(),
            "description": NSNull(),
            "camel_case_company_attributes": [
                "inflection_id": 1
            ]
            ] as [String : Any]

        let result = user.hyp_dictionary(using: .snakeCase, andRelationshipType: .nested)
        print(result)
        XCTAssertEqual(compared as NSDictionary, result as NSDictionary)

        dataStack.drop()
    }

    func testExportDictionaryWithCamelCaseRelationshipNested() {
        // Fill in transformable attributes is not supported in Swift 3. Crashes when saving the context.
        let dataStack = Helper.dataStackWithModelName("137")
        let user = NSEntityDescription.insertNewObject(forEntityName: "InflectionUser", into: dataStack.mainContext)
        user.hyp_fill(with: self.sampleSnakeCaseJSONWithRelationship)

        let company = NSEntityDescription.insertNewObject(forEntityName: "InflectionCompany", into: dataStack.mainContext)
        company.setValue(NSNumber(value: 1), forKey: "inflectionID")
        user.setValue(company, forKey: "camelCaseCompany")

        try! dataStack.mainContext.save()

        let compared = [
            "inflectionBinaryData": NSNull(),
            "inflectionDate": NSNull(),
            "inflectionID": 1,
            "inflectionInteger": NSNull(),
            "inflectionString": NSNull(),
            "randomRemoteKey": NSNull(),
            "description": NSNull(),
            "camelCaseCompanyAttributes": [
                "inflectionID": 1
            ]
            ] as [String : Any]

        let result = user.hyp_dictionary(using: .camelCase, andRelationshipType: .nested)
        print(result)
        XCTAssertEqual(compared as NSDictionary, result as NSDictionary)
        
        dataStack.drop()
    }

    func testReservedAttributeNotExportingWell() {
        let dataStack = Helper.dataStackWithModelName("142")
        let user = NSEntityDescription.insertNewObject(forEntityName: "TwoLetterEntity", into: dataStack.mainContext)
        user.hyp_fill(with: ["description": "test"])
        try! dataStack.mainContext.save()

        let compared = ["description": "test"] as [String : Any]

        let result = user.hyp_dictionary(using: .camelCase)
        print(result)
        XCTAssertEqual(compared as NSDictionary, result as NSDictionary)

        dataStack.drop()
    }

    func setUpWorkout(dataStack: DataStack) -> NSManagedObject {
        let workout = NSEntityDescription.insertNewObject(forEntityName: "Workout", into: dataStack.mainContext)
        workout.setValue(UUID().uuidString, forKey: "id")
        workout.setValue(UUID().uuidString, forKey: "workoutDesc")
        workout.setValue(UUID().uuidString, forKey: "workoutName")

        let calendar = NSEntityDescription.insertNewObject(forEntityName: "Calendar", into: dataStack.mainContext)
        calendar.setValue(UUID().uuidString, forKey: "eventSourceType")
        calendar.setValue(UUID().uuidString, forKey: "id")
        calendar.setValue(NSNumber(value: true), forKey: "isCompleted")
        calendar.setValue(Date(timeIntervalSince1970: 0), forKey: "start")

        let plannedToIDs = NSMutableSet()
        plannedToIDs.add(calendar)
        workout.setValue(plannedToIDs, forKey: "plannedToIDs")

        let exercise = NSEntityDescription.insertNewObject(forEntityName: "Exercise", into: dataStack.mainContext)
        exercise.setValue(UUID().uuidString, forKey: "exerciseDesc")
        exercise.setValue(UUID().uuidString, forKey: "exerciseName")
        exercise.setValue(UUID().uuidString, forKey: "id")
        exercise.setValue(UUID().uuidString, forKey: "mainMuscle")

        let exerciseSet = NSEntityDescription.insertNewObject(forEntityName: "ExerciseSet", into: dataStack.mainContext)
        exerciseSet.setValue(UUID().uuidString, forKey: "id")
        exerciseSet.setValue(NSNumber(value: true), forKey: "isCompleted")
        exerciseSet.setValue(NSNumber(value: 0), forKey: "setNumber")
        exerciseSet.setValue(NSNumber(value: 0), forKey: "setReps")
        exerciseSet.setValue(NSNumber(value: 0), forKey: "setWeight")

        let exerciseSets = NSMutableSet()
        exerciseSets.add(exerciseSet)
        exercise.setValue(exerciseSets, forKey: "exerciseSets")

        let workoutExercises = NSMutableSet()
        workoutExercises.add(exercise)
        workout.setValue(workoutExercises, forKey: "workoutExercises")

        try! dataStack.mainContext.save()

        return workout
    }

    func testBug140CamelCase() {
        let dataStack = Helper.dataStackWithModelName("140")

        let workout = self.setUpWorkout(dataStack: dataStack)

        let result = workout.hyp_dictionary(using: .camelCase, andRelationshipType: .array)

        let rootKeys = Array(result.keys)
        XCTAssertEqual(rootKeys.count, 5)
        XCTAssertEqual(rootKeys[0], "plannedToIDs")
        XCTAssertEqual(rootKeys[1], "workoutName")
        XCTAssertEqual(rootKeys[2], "_id")
        XCTAssertEqual(rootKeys[3], "workoutExercises")
        XCTAssertEqual(rootKeys[4], "workoutDesc")

        dataStack.drop()
    }

    func testBug140SnakeCase() {
        let dataStack = Helper.dataStackWithModelName("140")

        let workout = self.setUpWorkout(dataStack: dataStack)

        let result = workout.hyp_dictionary(using: .snakeCase, andRelationshipType: .array)

        let rootKeys = Array(result.keys)
        XCTAssertEqual(rootKeys.count, 5)
        XCTAssertEqual(rootKeys[0], "planned_to_ids")
        XCTAssertEqual(rootKeys[1], "_id")
        XCTAssertEqual(rootKeys[2], "workout_desc")
        XCTAssertEqual(rootKeys[3], "workout_name")
        XCTAssertEqual(rootKeys[4], "workout_exercises")

        dataStack.drop()
    }
}
