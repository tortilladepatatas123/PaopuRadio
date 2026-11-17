// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import AVFoundation
import Combine
import MediaPlayer
import os
import UIKit

enum PlaybackState: Equatable {
    case idle, loading, playing, paused, failed

    /// Texto para mostrar en el reproductor.
    var label: String {
        switch self {
        case .idle: return ""
        case .loading: return "Conectando…"
        case .playing: return "En directo"
        case .paused: return "En pausa"
        case .failed: return "No se pudo reproducir"
        }
    }
}

/// Lo que el stream dice que está sonando ahora mismo (título, artista y, si la emisora lo envía, carátula).
struct StreamMetadata: Equatable, Sendable {
    var title: String?
    var artist: String?
    var artwork: Data?
}

/// Recibe los metadatos en tiempo real del stream (ICY, ID3, HLS) y los entrega ya interpretados.
final class MetadataReceiver: NSObject, AVPlayerItemMetadataOutputPushDelegate, @unchecked Sendable {
    private let handler: @Sendable (StreamMetadata) -> Void

    init(handler: @escaping @Sendable (StreamMetadata) -> Void) {
        self.handler = handler
    }

    func metadataOutput(
        _ output: AVPlayerItemMetadataOutput,
        didOutputTimedMetadataGroups groups: [AVTimedMetadataGroup],
        from track: AVPlayerItemTrack?
    ) {
        var result = StreamMetadata()
        for item in groups.flatMap(\.items) {
            guard let identifier = item.identifier else { continue }
            if Self.titleIDs.contains(identifier), let raw = item.stringValue {
                let parsed = Self.parse(raw)
                result.title = parsed.title
                result.artist = result.artist ?? parsed.artist
            } else if Self.artistIDs.contains(identifier), let raw = item.stringValue {
                result.artist = Self.clean(raw)
            } else if Self.artworkIDs.contains(identifier), let data = item.dataValue {
                result.artwork = data
            }
        }
        handler(result)
    }

    private static let titleIDs: Set<AVMetadataIdentifier> = [
        .icyMetadataStreamTitle, .commonIdentifierTitle, .id3MetadataTitleDescription, .iTunesMetadataSongName
    ]
    private static let artistIDs: Set<AVMetadataIdentifier> = [
        .commonIdentifierArtist, .id3MetadataLeadPerformer, .iTunesMetadataArtist
    ]
    private static let artworkIDs: Set<AVMetadataIdentifier> = [
        .commonIdentifierArtwork, .id3MetadataAttachedPicture, .iTunesMetadataCoverArt
    ]

    private static func clean(_ raw: String) -> String? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? nil : text
    }

    /// Casi todas las emisoras envían "Artista - Título" en un solo campo.
    static func parse(_ raw: String) -> (title: String?, artist: String?) {
        guard let text = clean(raw) else { return (nil, nil) }
        guard let range = text.range(of: " - ") else { return (text, nil) }
        let artist = clean(String(text[..<range.lowerBound]))
        let title = clean(String(text[range.upperBound...]))
        return (title ?? text, title == nil ? nil : artist)
    }
}

private struct ImageBox: @unchecked Sendable {
    let image: UIImage
}

/// Fuente de verdad del estado de reproducción. Gestiona AVPlayer, la sesión de audio,
/// los metadatos en directo y la información de la pantalla de bloqueo.
@MainActor
final class PlayerService: ObservableObject {
    @Published private(set) var current: Station?
    @Published private(set) var state: PlaybackState = .idle
    /// Lo que suena ahora según el stream (vacío si la emisora no envía metadatos).
    @Published private(set) var metadata = StreamMetadata()
    /// Carátula enviada por la emisora en los metadatos, si la hay.
    @Published private(set) var artwork: UIImage?
    /// Controla la hoja del reproductor a pantalla completa.
    @Published var showNowPlaying = false

    private let player = AVPlayer()
    private let logger = Logger(subsystem: "com.paopu.app", category: "player")
    private var cancellables = Set<AnyCancellable>()
    private var itemObserver: AnyCancellable?
    private var receiver: MetadataReceiver?
    private var logoImage: UIImage?
    private var logoTask: Task<Void, Never>?

    init() {
        player.automaticallyWaitsToMinimizeStalling = true
        configureAudioSession()
        configureRemoteCommands()

        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                MainActor.assumeIsolated { self?.timeControlChanged(status) }
            }
            .store(in: &cancellables)
    }

    var isPlaying: Bool { state == .playing || state == .loading }

    /// Hay un tema identificado en el stream.
    var hasSong: Bool { metadata.title != nil }

    func play(_ station: Station) {
        if current?.id == station.id, state != .failed {
            resume()
            return
        }
        current = station
        state = .loading
        metadata = StreamMetadata()
        artwork = nil
        loadLogo(for: station)

        let item = AVPlayerItem(url: station.streamURL)
        attachMetadataOutput(to: item)
        itemObserver = item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                MainActor.assumeIsolated {
                    if status == .failed { self?.itemFailed() }
                }
            }
        player.replaceCurrentItem(with: item)
        player.play()
        updateNowPlaying()
    }

    func resume() {
        guard current != nil else { return }
        if state == .failed, let station = current {
            current = nil
            play(station)
            return
        }
        player.play()
    }

    func pause() {
        player.pause()
    }

    func toggle() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        itemObserver = nil
        receiver = nil
        logoTask?.cancel()
        logoImage = nil
        current = nil
        metadata = StreamMetadata()
        artwork = nil
        state = .idle
        showNowPlaying = false
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        MPNowPlayingInfoCenter.default().playbackState = .stopped
    }

    // MARK: - Metadatos

    private func attachMetadataOutput(to item: AVPlayerItem) {
        let output = AVPlayerItemMetadataOutput(identifiers: nil)
        let receiver = MetadataReceiver { [weak self] value in
            Task { @MainActor in self?.apply(value) }
        }
        output.setDelegate(receiver, queue: .main)
        item.add(output)
        self.receiver = receiver
    }

    private func apply(_ value: StreamMetadata) {
        metadata = value
        artwork = value.artwork.flatMap { UIImage(data: $0) }
        updateNowPlaying()
    }

    /// Descarga el logo de la emisora para usarlo como carátula cuando el stream no envía una.
    private func loadLogo(for station: Station) {
        logoTask?.cancel()
        logoImage = nil
        guard let url = station.faviconURL else { return }
        logoTask = Task {
            let result = try? await URLSession.shared.data(from: url)
            guard !Task.isCancelled, current?.id == station.id,
                  let data = result?.0, let image = UIImage(data: data) else { return }
            logoImage = image
            updateNowPlaying()
        }
    }

    // MARK: - Privado

    private func timeControlChanged(_ status: AVPlayer.TimeControlStatus) {
        guard current != nil, state != .failed else { return }
        switch status {
        case .playing: state = .playing
        case .waitingToPlayAtSpecifiedRate: state = .loading
        case .paused: state = .paused
        @unknown default: break
        }
        updateNowPlaying()
    }

    private func itemFailed() {
        logger.error("Fallo al reproducir \(self.current?.name ?? "?", privacy: .public)")
        state = .failed
        updateNowPlaying()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            logger.error("No se pudo activar la sesión de audio: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func configureRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.toggle() }
            return .success
        }
    }

    /// Pantalla de bloqueo, Centro de control, CarPlay, AirPods…: tema y artista en directo, y como carátula
    /// la de los metadatos o, si no hay, el logo de la emisora.
    private func updateNowPlaying() {
        guard let station = current else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: metadata.title ?? station.name,
            MPMediaItemPropertyArtist: hasSong ? (metadata.artist ?? station.name) : "Paopu Radio",
            MPMediaItemPropertyAlbumTitle: station.name,
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: state == .playing ? 1.0 : 0.0
        ]
        if let image = artwork ?? logoImage {
            info[MPMediaItemPropertyArtwork] = Self.makeArtwork(image)
        }
        let center = MPNowPlayingInfoCenter.default()
        center.nowPlayingInfo = info
        center.playbackState = state == .playing ? .playing : .paused
    }

    /// Fuera del actor principal: el sistema llama a este cierre desde otro hilo.
    nonisolated private static func makeArtwork(_ image: UIImage) -> MPMediaItemArtwork {
        let box = ImageBox(image: image)
        return MPMediaItemArtwork(boundsSize: image.size) { _ in box.image }
    }
}
