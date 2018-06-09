import XCTest
import Sync

class DateTests: XCTestCase {

    func testDateA() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-06-23T12:40:08.123")
        let resultDate = NSDate(fromDateString: "2015-06-23T14:40:08.123+02:00")! as Date

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date.timeIntervalSince1970, resultDate.timeIntervalSince1970)
    }

    func testDateB() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2014-01-01T12:40:08.000")
        let resultDate = NSDate(fromDateString: "2014-01-01T12:40:08+00:00")! as Date

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateC() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2014-01-02T00:00:00.000")
        let resultDate = NSDate(fromDateString: "2014-01-02")! as Date

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateD() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2014-01-02T12:40:08.123")
        let resultDate = NSDate(fromDateString: "2014-01-02T12:40:08.123000+00:00")! as Date

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateE() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-09-10T12:40:08.123")
        let resultDate = NSDate(fromDateString: "2015-09-10T12:40:08.123+0000")! as Date

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateF() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-09-10T12:40:08.123")
        let resultDate = NSDate(fromDateString: "2015-09-10T12:40:08.123456Z")! as Date

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateG() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-06-23T19:04:19.911Z")
        let resultDate = NSDate(fromDateString: "2015-06-23T19:04:19.911Z")! as Date
        print(date.timeIntervalSince1970)
        print(resultDate.timeIntervalSince1970)
        date.prettyPrint()

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateH() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2014-03-30T09:13:10.000Z")
        let resultDate = NSDate(fromDateString: "2014-03-30T09:13:10Z")! as Date
        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateI() {
        let resultDate = NSDate(fromDateString: "2014-01-02T00:monsterofthelakeI'mhere00:00.007450+00:00")
        XCTAssertNil(resultDate)
    }

    func testDateJ() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2016-01-09T12:40:08.120")
        let resultDate = NSDate(fromDateString: "2016-01-09T12:40:08.12")! as Date
        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateK() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2016-01-09T12:40:08.000")
        let resultDate = NSDate(fromDateString: "2016-01-09T12:40:08")! as Date
        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testDateL() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2009-10-09T12:40:08.000")
        let resultDate = NSDate(fromDateString: "2009-10-09 12:40:08")! as Date
        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }
}

class TimestampDateTests: XCTestCase {

    func testTimestampA() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-09-10T12:40:08.123")
        let resultDate = NSDate(fromDateString: "1441843200")! as Date

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testTimestampB() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-09-10T12:40:08.123")
        let resultDate = NSDate(fromDateString: "1441843200000000")! as Date

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testTimestampC() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-09-10T12:40:08.123")
        let resultDate = NSDate(fromUnixTimestampNumber: 1441843200)! as Date

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }

    func testTimestampD() {
        let date = Date.dateWithHourAndTimeZoneString(dateString: "2015-09-10T12:40:08.123")
        let resultDate = NSDate(fromUnixTimestampNumber: NSNumber(value: 1441843200000000.0))! as Date

        XCTAssertNotNil(resultDate)
        XCTAssertEqual(date, resultDate)
    }
}

class OtherDateTests: XCTestCase {

    func testDateType() {
        let isoDateType = "2014-01-02T00:00:00.007450+00:00".dateType()
        XCTAssertEqual(isoDateType, DateType.iso8601)

        let timestampDateType = "1441843200000000".dateType()
        XCTAssertEqual(timestampDateType, DateType.unixTimestamp)
    }
}

extension Date {
    static func dateWithHourAndTimeZoneString(dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let date = formatter.date(from: dateString)!

        return date
    }

    func prettyPrint() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        let string = formatter.string(from: self)
        print(string)
    }
}
