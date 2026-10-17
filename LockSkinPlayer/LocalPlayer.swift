import AVFoundation
import MediaPlayer
import UniformTypeIdentifiers
import UIKit

struct LocalTrack: Identifiable, Codable, Equatable {
    var id: UUID
    var fileName: String
    var title: String
}

@MainActor
final class LocalPlayer: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var tracks: [LocalTrack] = []
    @Published private(set) var currentIndex: Int? = nil
    @Published private(set) var isPlaying = false
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var errorMessage: String?
    @Published var skin: Skin = .classic {
        didSet {
            UserDefaults.standard.set(skin.rawValue, forKey: "selectedSkin")
            publishNowPlaying()
        }
    }

    private var audio: AVAudioPlayer?
    private var ticker: Timer?
    private let fileManager = FileManager.default
    private var documents: URL { fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    private var manifest: URL { documents.appendingPathComponent("library.json") }
    var currentTrack: LocalTrack? {
        guard let currentIndex, tracks.indices.contains(currentIndex) else { return nil }
        return tracks[currentIndex]
    }

    override init() {
        super.init()
        if let saved = UserDefaults.standard.string(forKey: "selectedSkin"), let theme = Skin(rawValue: saved) { skin = theme }
        if let data = try? Data(contentsOf: manifest), let decoded = try? JSONDecoder().decode([LocalTrack].self, from: data) {
            tracks = decoded.filter { fileManager.fileExists(atPath: documents.appendingPathComponent($0.fileName).path) }
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            errorMessage = "Audio session unavailable: \(error.localizedDescription)"
        }
        configureRemoteCommands()
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        ticker = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
    }

    deinit {
        ticker?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    func importFiles(_ urls: [URL]) {
        for url in urls {
            let access = url.startAccessingSecurityScopedResource()
            defer { if access { url.stopAccessingSecurityScopedResource() } }
            do {
                let id = UUID()
                let ext = url.pathExtension.isEmpty ? "audio" : url.pathExtension.lowercased()
                let name = "\(id.uuidString).\(ext)"
                try fileManager.copyItem(at: url, to: documents.appendingPathComponent(name))
                tracks.append(LocalTrack(id: id, fileName: name, title: url.deletingPathExtension().lastPathComponent))
            } catch {
                errorMessage = "Could not import \(url.lastPathComponent): \(error.localizedDescription)"
            }
        }
        saveLibrary()
        if currentIndex == nil && !tracks.isEmpty { loadTrack(at: 0, autoplay: false) }
    }

    func select(_ track: LocalTrack) {
        guard let index = tracks.firstIndex(of: track) else { return }
        loadTrack(at: index, autoplay: true)
    }

    func togglePlayback() {
        if isPlaying {
            audio?.pause()
            isPlaying = false
        } else {
            if audio == nil, !tracks.isEmpty { loadTrack(at: currentIndex ?? 0, autoplay: false) }
            do { try AVAudioSession.sharedInstance().setActive(true) }
            catch { errorMessage = "Audio session unavailable: \(error.localizedDescription)"; return }
            guard audio?.play() == true else { return }
            isPlaying = true
        }
        publishNowPlaying()
    }

    func next() {
        guard !tracks.isEmpty else { return }
        loadTrack(at: ((currentIndex ?? -1) + 1) % tracks.count, autoplay: true)
    }

    func previous() {
        guard !tracks.isEmpty else { return }
        if elapsed > 3 { seek(to: 0); return }
        loadTrack(at: ((currentIndex ?? 0) - 1 + tracks.count) % tracks.count, autoplay: true)
    }

    func seek(to value: TimeInterval) {
        guard let audio else { return }
        audio.currentTime = max(0, min(value, audio.duration))
        elapsed = audio.currentTime
        publishNowPlaying()
    }

    private func loadTrack(at index: Int, autoplay: Bool) {
        guard tracks.indices.contains(index) else { return }
        let file = documents.appendingPathComponent(tracks[index].fileName)
        do {
            let loaded = try AVAudioPlayer(contentsOf: file)
            loaded.delegate = self
            loaded.prepareToPlay()
            audio?.stop()
            audio = loaded
            currentIndex = index
            duration = loaded.duration
            elapsed = 0
            isPlaying = autoplay && loaded.play()
            publishNowPlaying()
        } catch {
            errorMessage = "Could not play \(tracks[index].title): \(error.localizedDescription)"
        }
    }

    private func saveLibrary() {
        do { try JSONEncoder().encode(tracks).write(to: manifest, options: .atomic) }
        catch { errorMessage = "Could not save library: \(error.localizedDescription)" }
    }

    @objc private func tick() {
        guard let audio, isPlaying else { return }
        elapsed = audio.currentTime
        // Avoid redrawing artwork each second. The system advances elapsed time from playback rate.
    }

    private func publishNowPlaying() {
        guard let track = currentTrack else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        let image = SkinArtwork.render(skin, title: track.title)
        let art = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: "Local audio",
            MPMediaItemPropertyAlbumTitle: skin.rawValue,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPMediaItemPropertyArtwork: art,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
    }

    private func configureRemoteCommands() {
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in if !self.isPlaying { self.togglePlayback() } }
            return .success
        }
        commands.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in if self.isPlaying { self.togglePlayback() } }
            return .success
        }
        commands.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.togglePlayback() }
            return .success
        }
        commands.nextTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.next() }
            return .success
        }
        commands.previousTrackCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            Task { @MainActor in self.previous() }
            return .success
        }
        commands.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, let change = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in self.seek(to: change.positionTime) }
            return .success
        }
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let value = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: value) else { return }
        if type == .began {
            audio?.pause()
            isPlaying = false
            publishNowPlaying()
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let currentIndex, currentIndex + 1 < tracks.count {
            loadTrack(at: currentIndex + 1, autoplay: true)
        } else {
            isPlaying = false
            elapsed = duration
            publishNowPlaying()
        }
    }
}
