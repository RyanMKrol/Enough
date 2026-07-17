import AVFoundation
import Foundation

final class AudioService {
  private let content: ContentStore
  private var currentPlayer: AVAudioPlayer?
  private var playedCardIds: Set<String> = []
  // SAFE: deinit is nonisolated by language rule and NSObjectProtocol observer tokens are
  // documented as safe to remove from any thread, so this is the standard teardown escape valve.
  private nonisolated(unsafe) var interruptionObserverToken: (any NSObjectProtocol)?

  var playHandler: ((URL) -> Void)?

  init(content: ContentStore) {
    self.content = content

    let session = AVAudioSession.sharedInstance()
    interruptionObserverToken = NotificationCenter.default.addObserver(
      forName: AVAudioSession.interruptionNotification,
      object: session,
      queue: .main
    ) { [weak self] notification in
      let interruptionTypeValue =
        notification.userInfo?["AVAudioSessionInterruptionTypeKey"] as? UInt
      guard let rawValue = interruptionTypeValue,
        let interruptionType = AVAudioSession.InterruptionType(rawValue: rawValue),
        interruptionType == .began
      else {
        return
      }

      // SAFE: queue: .main guarantees delivery on the main thread; MainActor.assumeIsolated
      // documents that guarantee instead of widening the whole class to @unchecked Sendable.
      MainActor.assumeIsolated {
        self?.currentPlayer?.stop()
      }
    }
  }

  deinit {
    if let token = interruptionObserverToken {
      NotificationCenter.default.removeObserver(token)
    }
  }

  func play(fileName: String) {
    guard let url = content.audioURL(forFile: fileName) else {
      return
    }

    if let playHandler = playHandler {
      playHandler(url)
      return
    }

    currentPlayer?.stop()

    do {
      let player = try AVAudioPlayer(contentsOf: url)
      self.currentPlayer = player
      player.play()
    } catch {
      // Silently ignore audio player creation/playback errors
    }
  }

  func autoPlayOnce(cardId: String, fileName: String) {
    guard !playedCardIds.contains(cardId) else {
      return
    }

    playedCardIds.insert(cardId)
    play(fileName: fileName)
  }

  func resetAutoPlay() {
    playedCardIds.removeAll()

    guard playHandler == nil else {
      return
    }

    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .default, options: [.duckOthers])
    try? session.setActive(true, options: .notifyOthersOnDeactivation)
  }

  func sessionEnded() {
    currentPlayer?.stop()

    guard playHandler == nil else {
      return
    }

    let session = AVAudioSession.sharedInstance()
    try? session.setActive(false, options: .notifyOthersOnDeactivation)
  }
}
