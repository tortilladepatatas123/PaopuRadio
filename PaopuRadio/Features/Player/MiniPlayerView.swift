// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import SwiftUI

/// Reproductor compacto persistente en la parte inferior.
struct MiniPlayerView: View {
    @EnvironmentObject private var player: PlayerService

    var body: some View {
        if let station = player.current {
            HStack(spacing: 12) {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .frame(width: 36, height: 36)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name).font(.subheadline.weight(.semibold)).lineLimit(1)
                    Text(statusText).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()

                if player.state == .loading {
                    ProgressView()
                }
                Button {
                    player.toggle()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(player.isPlaying ? "Pausar" : "Reproducir")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .overlay(alignment: .top) { Divider() }
            .transition(.move(edge: .bottom))
        }
    }

    private var statusText: String {
        switch player.state {
        case .idle: return ""
        case .loading: return "Conectando…"
        case .playing: return "En directo"
        case .paused: return "En pausa"
        case .failed: return "No se pudo reproducir"
        }
    }
}
