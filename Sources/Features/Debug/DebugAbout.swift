import Foundation

enum DebugAbout {
  static let section = DebugSection(
    id: "about",
    title: "About",
    rows: [
      DebugRow(
        id: "app-version",
        title: "App version",
        kind: .info { _ in
          let bundle = Bundle.main
          let version =
            bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
          let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
          return "\(version) (\(build))"
        }
      ),
      DebugRow(
        id: "active-trip",
        title: "Active trip",
        kind: .info { services in
          do {
            guard let trip = try services.tripStore.activeTrip() else { return "none" }
            let day = try? services.tripStore.dayNumber(now: services.dateProvider.now)
            let dayText = day.map { "day \($0)" } ?? "day ?"
            return "\(trip.countryId) · \(trip.duration) · \(dayText)"
          } catch {
            return "unavailable"
          }
        }
      ),  // swiftlint:disable:this trailing_comma
    ]
  )
}
