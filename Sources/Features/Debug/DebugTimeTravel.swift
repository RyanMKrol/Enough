import Foundation

enum DebugTimeTravel {
  static let section = DebugSection(
    id: "time",
    title: "Time",
    rows: [
      DebugRow(
        id: "time-travel",
        title: "Time travel",
        subtitle: "Shifts every date the app sees",
        kind: .stepper(
          get: { services in
            TimeTravel.offset(in: services) ?? 0
          },
          set: { services, days in
            TimeTravel.setOffset(days, in: services)
          },
          label: { days in
            TimeTravel.label(for: days)
          }
        )
      )
    ]
  )
}
