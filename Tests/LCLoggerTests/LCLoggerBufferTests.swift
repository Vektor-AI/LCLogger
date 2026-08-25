import XCTest
import Combine
@testable import LCLogger

/// The in-memory log buffer feeds the debug viewer. It used to grow without
/// bound for as long as the logger was enabled — on a driver's 8-hour shift
/// in a TestFlight build that is a slow, permanent memory leak (VEK-10681).
/// The buffer is a tail: it keeps the newest `maxStoredLogs` entries and
/// drops the oldest.
final class LCLoggerBufferTests: XCTestCase {

    override func setUp() {
        super.setUp()
        LCLogger.logs.send([])
    }

    override func tearDown() {
        LCLogger.logs.send([])
        super.tearDown()
    }

    func testBufferKeepsOnlyTheNewestEntriesOnceTheCapIsReached() {
        let logger = LCLogger.shared()
        let overflow = 50

        for index in 0..<(LCLogger.maxStoredLogs + overflow) {
            logger.log("msg-\(index)")
        }

        XCTAssertEqual(LCLogger.logs.value.count, LCLogger.maxStoredLogs,
                       "the buffer must stay bounded no matter how long the session runs")
        XCTAssertEqual(LCLogger.logs.value.first?.message, "msg-\(overflow)",
                       "overflow drops the oldest entries — the buffer is the tail of the session")
        XCTAssertEqual(LCLogger.logs.value.last?.message, "msg-\(LCLogger.maxStoredLogs + overflow - 1)",
                       "the newest entry must always survive")
    }

    func testBufferBelowTheCapKeepsEveryEntryInOrder() {
        let logger = LCLogger.shared()

        for index in 0..<10 {
            logger.log("msg-\(index)")
        }

        XCTAssertEqual(LCLogger.logs.value.count, 10)
        XCTAssertEqual(LCLogger.logs.value.map(\.message), (0..<10).map { "msg-\($0)" })
    }

    func testDisabledLoggerDoesNotAccumulateAnything() {
        let logger = LCLogger.shared()
        logger.enabled = false

        logger.log("invisible")

        XCTAssertTrue(LCLogger.logs.value.isEmpty,
                      "a disabled logger (production builds) must never grow the buffer")
    }
}
