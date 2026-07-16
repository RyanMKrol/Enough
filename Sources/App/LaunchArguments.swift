import Foundation
import SwiftData

/// Handles process launch arguments used by tooling (e.g. the visual-verification script's
/// `-demo-state`), which must apply before the first frame renders.
enum LaunchArguments {
  static func handle(services: AppServices) {
    guard ProcessInfo.processInfo.arguments.contains("-demo-state") else { return }
    let context = ModelContext(services.container)
    try? DemoSeeder.seed(
      content: services.contentStore, context: context, now: services.dateProvider.now)
  }
}
