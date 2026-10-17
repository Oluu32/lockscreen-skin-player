import SwiftUI
import UniformTypeIdentifiers

struct PlayerView: View {
    @EnvironmentObject private var player: LocalPlayer
    @State private var importing = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(uiImage: SkinArtwork.render(player.skin, title: player.currentTrack?.title ?? "NO TRACK LOADED"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .accessibilityLabel("\(player.skin.rawValue) artwork")
                    VStack(alignment: .leading, spacing: 7) {
                        Text(player.currentTrack?.title ?? "Import an audio file to start")
                            .font(.headline)
                            .lineLimit(2)
                        HStack {
                            Text(time(player.elapsed))
                            Spacer()
                            Text(time(player.duration))
                        }
                        .font(.caption.monospacedDigit())
                        Slider(value: Binding(get: { player.elapsed }, set: { player.seek(to: $0) }), in: 0...max(player.duration, 1))
                            .disabled(player.currentTrack == nil)
                    }
                    HStack(spacing: 38) {
                        Button(action: player.previous) { Image(systemName: "backward.end.fill") }
                            .accessibilityLabel("Previous track")
                        Button(action: player.togglePlayback) {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 35))
                        }
                        .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                        Button(action: player.next) { Image(systemName: "forward.end.fill") }
                            .accessibilityLabel("Next track")
                    }
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .disabled(player.tracks.isEmpty)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Skin theme").font(.headline)
                        Picker("Skin theme", selection: $player.skin) {
                            ForEach(Skin.allCases) { skin in Text(skin.rawValue).tag(skin) }
                        }
                        .pickerStyle(.segmented)
                        .font(.caption)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Your files").font(.headline)
                            Spacer()
                            Button("Import audio") { importing = true }
                        }
                        ForEach(player.tracks) { track in
                            Button { player.select(track) } label: {
                                HStack {
                                    Image(systemName: player.currentTrack?.id == track.id ? "music.note.list" : "music.note")
                                    Text(track.title).lineLimit(1)
                                    Spacer()
                                    if player.currentTrack?.id == track.id { Image(systemName: "speaker.wave.2") }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        if player.tracks.isEmpty { Text("Files are copied into this app. They stay on the phone.").font(.subheadline).foregroundStyle(.secondary) }
                    }
                }
                .padding()
            }
            .navigationTitle("Lock Skin Player")
            .fileImporter(isPresented: $importing, allowedContentTypes: [.audio], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls): player.importFiles(urls)
                case .failure(let error): player.errorMessage = "Import failed: \(error.localizedDescription)"
                }
            }
            .alert("Player", isPresented: Binding(get: { player.errorMessage != nil }, set: { if !$0 { player.errorMessage = nil } })) {
                Button("OK", role: .cancel) { player.errorMessage = nil }
            } message: { Text(player.errorMessage ?? "") }
        }
        .tint(Color(uiColor: player.skin.accent))
    }

    private func time(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "0:00" }
        let total = Int(max(0, seconds))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
