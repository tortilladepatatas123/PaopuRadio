// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import AVFoundation
import Combine
import MediaPlayer
import os

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

/// Fuente de verdad del estado de reproducción. Gestiona AVPlayer, la sesión de audio
/// y los controles de la pantalla de bloqueo.
@MainActor
final class PlayerService: ObservableObject {
    @Published private(set) var current: Station?
    @Published private(set) var state: PlaybackState = .idle
    /// Controla la hoja del reproductor a pantalla completa.
    @Published var showNowPlaying = false

    private let player = AVPlayer()
    private let logger = Logger(subsystem: "com.paopu.app", category: "player")
    private var cancellables = Set<AnyCancellable>()
    private var itemObserver: AnyCancellable?

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

    func play(_ station: Station) {
        if current?.id == station.id, state != .failed {
            resume()
            return
        }
        current = station
        state = .loading

        let item = AVPlayerItem(url: station.streamURL)
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
        current = nil
        state = .idle
        showNowPlaying = false
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
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
    }

    private func itemFailed() {
        logger.error("Fallo al reproducir \(self.current?.name ?? "?", privacy: .public)")
        state = .failed
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

    private func updateNowPlaying() {
        guard let station = current else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: station.name,
            MPMediaItemPropertyArtist: "Paopu Radio",
            MPNowPlayingInfoPropertyIsLiveStream: true
        ]
    }
}
