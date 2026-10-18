import AVFoundation
import Combine
import Foundation
import SwiftData

/// Owns one editor's microphone and playback session. Recordings remain in a
/// scratch file until saved as a regular NoteDocument attachment.
@MainActor
final class NoteAudioController: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    @Published private(set) var isRecording = false
    @Published private(set) var isRequestingPermission = false
    @Published private(set) var draftURL: URL?
    @Published private(set) var recordingDuration: TimeInterval = 0
    @Published private(set) var level: CGFloat = 0
    @Published private(set) var isPlaying = false
    @Published private(set) var playingID: PersistentIdentifier?
    @Published private(set) var playbackTime: TimeInterval = 0
    @Published private(set) var playbackDuration: TimeInterval = 0
    @Published var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var pendingURL: URL?
    private var permissionRequest = UUID()

    func startRecording() async {
        guard !isRecording, !isRequestingPermission, draftURL == nil else { return }
        stopPlayback()
        let request = UUID()
        permissionRequest = request
        isRequestingPermission = true
        let allowed = await AVAudioApplication.requestRecordPermission()
        guard permissionRequest == request else { return }
        isRequestingPermission = false
        guard allowed else {
            errorMessage = "Microphone access is off. Enable it for NOMA in Settings to record audio."
            return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".m4a")
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            let recorder = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ])
            recorder.delegate = self
            recorder.isMeteringEnabled = true
            self.recorder = recorder
            pendingURL = url
            guard recorder.record() else { throw AudioError.couldNotRecord }
            self.recorder = recorder
            pendingURL = url
            recordingDuration = 0
            isRecording = true
            startTimer()
        } catch {
            self.recorder = nil
            pendingURL = nil
            try? FileManager.default.removeItem(at: url)
            deactivateSession()
            errorMessage = "Couldn't start recording: \(error.localizedDescription)"
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        recordingDuration = max(recorder?.currentTime ?? 0, recordingDuration)
        isRecording = false
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
        draftURL = pendingURL
        pendingURL = nil
        level = 0
        deactivateSession()
    }

    func discardDraft() {
        stopRecording()
        if let draftURL { try? FileManager.default.removeItem(at: draftURL) }
        draftURL = nil
        recordingDuration = 0
    }

    /// Only clears the file after the caller has successfully saved its bytes.
    func draftData() throws -> Data {
        guard let draftURL else { throw AudioError.noRecording }
        let data = try Data(contentsOf: draftURL)
        guard !data.isEmpty else { throw AudioError.noRecording }
        // Validate the recording before adding it to the persistent store.
        let preview = try AVAudioPlayer(data: data)
        guard preview.duration > 0 else { throw AudioError.noRecording }
        return data
    }

    func togglePlayback(_ document: NoteDocument) {
        if playingID == document.persistentModelID, let player {
            if player.isPlaying {
                player.pause()
                isPlaying = false
                deactivateSession()
            } else {
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    guard player.play() else { throw AudioError.couldNotPlay }
                    isPlaying = true
                } catch {
                    stopPlayback()
                    errorMessage = "Couldn't resume playback: \(error.localizedDescription)"
                }
            }
            return
        }
        stopPlayback()
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            let player = try AVAudioPlayer(data: document.data)
            player.delegate = self
            guard player.play() else { throw AudioError.couldNotPlay }
            self.player = player
            isPlaying = true
            playbackDuration = player.duration
            playbackTime = 0
            playingID = document.persistentModelID
            startTimer()
        } catch {
            stopPlayback()
            errorMessage = "Couldn't play this recording: \(error.localizedDescription)"
        }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        playingID = nil
        isPlaying = false
        playbackTime = 0
        playbackDuration = 0
        if !isRecording {
            timer?.invalidate()
            timer = nil
            deactivateSession()
        }
    }

    /// Stop on interruptions/backgrounding, retaining the draft for review.
    func suspend() {
        permissionRequest = UUID()
        isRequestingPermission = false
        stopRecording()
        stopPlayback()
    }

    func close() {
        suspend()
        discardDraft()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let recorder = self.recorder, self.isRecording {
                    self.recordingDuration = recorder.currentTime
                    recorder.updateMeters()
                    self.level = CGFloat(max(0, min(1, (recorder.averagePower(forChannel: 0) + 50) / 50)))
                } else if let player = self.player {
                    self.playbackTime = player.currentTime
                }
            }
        }
    }

    private func deactivateSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self, self.isRecording else { return }
            self.stopRecording()
            if !flag { self.errorMessage = "Recording stopped unexpectedly. Save the captured audio or record again." }
        }
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor [weak self] in
            self?.stopRecording()
            self?.errorMessage = "Recording was interrupted. Try saving the captured audio or record again."
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in self?.stopPlayback() }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor [weak self] in
            self?.stopPlayback()
            self?.errorMessage = "This audio couldn't be played."
        }
    }

    static func timeString(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private enum AudioError: LocalizedError {
        case couldNotRecord, couldNotPlay, noRecording
        var errorDescription: String? {
            switch self {
            case .couldNotRecord: return "The microphone couldn't start."
            case .couldNotPlay: return "Playback couldn't start."
            case .noRecording: return "No playable audio was captured. Please record again."
            }
        }
    }
}
