import Foundation
import WatchConnectivity

final class WatchConnectivityModel: NSObject, ObservableObject, WCSessionDelegate {
    @Published var envelope = AppleWatchSyncEnvelope(isProUnlocked: false)
    @Published var connectionState: WatchConnectionState = .waitingForPhone

    private var session: WCSession? {
        WCSession.isSupported() ? WCSession.default : nil
    }

    func activate() {
        guard let session else {
            connectionState = .unsupported
            return
        }

        session.delegate = self
        session.activate()

        if let receivedEnvelope = envelope(from: session.receivedApplicationContext) {
            envelope = receivedEnvelope
            connectionState = .synced
        }
    }

    func requestSnapshot() {
        guard let session else {
            connectionState = .unsupported
            return
        }

        if let receivedEnvelope = envelope(from: session.receivedApplicationContext) {
            envelope = receivedEnvelope
            connectionState = .synced
        }

        guard session.isReachable else { return }
        session.sendMessage([AppleWatchSyncEnvelope.requestSnapshotKey: true]) { [weak self] reply in
            DispatchQueue.main.async {
                self?.applyApplicationContext(reply)
            }
        } errorHandler: { [weak self] _ in
            DispatchQueue.main.async {
                self?.connectionState = .waitingForPhone
            }
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        DispatchQueue.main.async {
            if let receivedEnvelope = self.envelope(from: session.receivedApplicationContext) {
                self.envelope = receivedEnvelope
                self.connectionState = .synced
            } else {
                self.connectionState = activationState == .activated ? .waitingForPhone : .unsupported
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.applyApplicationContext(applicationContext)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.applyApplicationContext(message)
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    private func applyApplicationContext(_ applicationContext: [String: Any]) {
        guard let receivedEnvelope = envelope(from: applicationContext) else { return }
        envelope = receivedEnvelope
        connectionState = .synced
    }

    private func envelope(from applicationContext: [String: Any]) -> AppleWatchSyncEnvelope? {
        guard let dictionary = applicationContext[AppleWatchSyncEnvelope.applicationContextKey] as? [String: Any] else {
            return nil
        }
        return AppleWatchSyncEnvelope(dictionary: dictionary)
    }
}

enum WatchConnectionState {
    case unsupported
    case waitingForPhone
    case synced
}
