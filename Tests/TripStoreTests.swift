import SwiftData
import XCTest

@testable import Enough

@MainActor
class TripStoreTests: XCTestCase {
  private func makeStore() throws -> (TripStore, ModelContext) {
    let container = try PersistenceStack.container(inMemory: true)
    let context = ModelContext(container)
    return (TripStore(context: context), context)
  }

  func testActiveTripIsNilOnEmptyStore() throws {
    let (store, _) = try makeStore()
    XCTAssertNil(try store.activeTrip())
  }

  func testSaveNewTripPersistsActiveTrip() throws {
    let (store, _) = try makeStore()
    let startDate = Date(timeIntervalSince1970: 1_700_000_000)

    try store.saveNewTrip(
      countryId: "japan",
      duration: "weekend",
      scenarioIds: ["greetings"],
      accentRawValue: "japan",
      startDate: startDate
    )

    let trip = try XCTUnwrap(try store.activeTrip())
    XCTAssertEqual(trip.countryId, "japan")
    XCTAssertEqual(trip.duration, "weekend")
    XCTAssertEqual(trip.scenarioIds, ["greetings"])
    XCTAssertEqual(trip.accentRawValue, "japan")
    XCTAssertEqual(trip.startDate, startDate)
    XCTAssertTrue(trip.isActive)
  }

  func testSecondSaveDeactivatesOldTrip() throws {
    let (store, context) = try makeStore()
    let startDate = Date(timeIntervalSince1970: 1_700_000_000)

    try store.saveNewTrip(
      countryId: "japan",
      duration: "weekend",
      scenarioIds: ["greetings"],
      accentRawValue: "japan",
      startDate: startDate
    )
    try store.saveNewTrip(
      countryId: "france",
      duration: "week",
      scenarioIds: ["eating-out"],
      accentRawValue: "france",
      startDate: startDate
    )

    let trip = try XCTUnwrap(try store.activeTrip())
    XCTAssertEqual(trip.countryId, "france")

    let allTrips = try context.fetch(FetchDescriptor<TripProfileRecord>())
    XCTAssertEqual(allTrips.count, 2)
    XCTAssertEqual(allTrips.filter(\.isActive).count, 1)
  }

  func testDayNumberComputesCalendarDaysAndClamps() throws {
    let (store, _) = try makeStore()
    let calendar = Calendar.current
    let startDate = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 9)))

    try store.saveNewTrip(
      countryId: "japan",
      duration: "weekend",
      scenarioIds: ["greetings"],
      accentRawValue: "japan",
      startDate: startDate
    )

    XCTAssertEqual(try store.dayNumber(now: startDate), 1)

    let nextDay = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: startDate))
    XCTAssertEqual(try store.dayNumber(now: nextDay), 2)

    let nextDayLate = try XCTUnwrap(
      calendar.date(from: DateComponents(year: 2026, month: 3, day: 11, hour: 23, minute: 59)))
    XCTAssertEqual(try store.dayNumber(now: nextDayLate), 2)

    let previousDay = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: startDate))
    XCTAssertEqual(try store.dayNumber(now: previousDay), 1)
  }

  func testDayNumberIsNilWhenNoActiveTrip() throws {
    let (store, _) = try makeStore()
    XCTAssertNil(try store.dayNumber(now: Date(timeIntervalSince1970: 1_700_000_000)))
  }

  func testResetDeletesAllTrips() throws {
    let (store, context) = try makeStore()
    let startDate = Date(timeIntervalSince1970: 1_700_000_000)

    try store.saveNewTrip(
      countryId: "japan",
      duration: "weekend",
      scenarioIds: ["greetings"],
      accentRawValue: "japan",
      startDate: startDate
    )
    try store.reset()

    XCTAssertNil(try store.activeTrip())
    XCTAssertTrue(try context.fetch(FetchDescriptor<TripProfileRecord>()).isEmpty)
  }
}
