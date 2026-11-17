// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import SwiftUI

/// Reproductor a pantalla completa: fondo con degradado propio de cada emisora, logo grande,
/// nombre, favorito, barra "en directo", controles y tarjetas con datos del stream.
struct NowPlayingView: View {
    @EnvironmentObject private var player: PlayerService
    @EnvironmentObject private var favorites: FavoritesStore

    var body: some View {
        Group {
            if let station = player.current {
                content(station)
            } else {
                Text("No hay nada en reproducción")
                    .foregroundStyle(Color.white.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background { NowPlayingBackground(seed: player.current?.id ?? "") }
        .foregroundStyle(Color.white)
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.dark)
    }

    private func content(_ station: Station) -> some View {
        VStack(spacing: 20) {
            StationArtwork(station: station, image: player.artwork, cornerRadius: 10)
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: Color.black.opacity(0.35), radius: 18, y: 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            titleRow(station)
            liveBar
            controls
            badges(station)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 12)
    }

    private func titleRow(_ station: Station) -> some View {
        let isFavorite = favorites.isFavorite(station)

        return HStack {
            Color.clear.frame(width: 36, height: 36)
            VStack(spacing: 4) {
                MarqueeText(
                    text: player.metadata.title ?? station.name,
                    font: .title3.bold(),
                    color: .white,
                    alignment: .center,
                    fps: 60
                )
                MarqueeText(
                    text: subtitle(station),
                    font: .body,
                    color: Color.white.opacity(0.75),
                    alignment: .center,
                    fps: 60
                )
            }
            .frame(maxWidth: .infinity)
            Button {
                favorites.toggle(station)
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isFavorite ? Color.yellow : Color.white.opacity(0.8))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Quitar de favoritos" : "Añadir a favoritos")
        }
    }

    /// Con tema identificado: artista (o emisora). Si no, los datos técnicos de la emisora.
    private func subtitle(_ station: Station) -> String {
        guard player.hasSong else { return station.detailText }
        return player.metadata.artist ?? station.name
    }

    /// En una radio no hay duración: la barra va llena y un icono de emisión en el centro indica el directo.
    private var liveBar: some View {
        let level = player.state == .playing ? 0.9 : 0.3

        return HStack(spacing: 12) {
            Capsule().fill(Color.white.opacity(level)).frame(height: 6)
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.white.opacity(level))
            Capsule().fill(Color.white.opacity(level)).frame(height: 6)
        }
        .frame(height: 28)
        .animation(.easeInOut(duration: 0.3), value: player.state)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("En directo")
    }

    private var controls: some View {
        HStack {
            AirPlayButton()
                .frame(width: 44, height: 44)
                .frame(maxWidth: .infinity)

            Button {
                player.toggle()
            } label: {
                PlayPauseIcon(isPlaying: player.isPlaying, size: 46)
                    .frame(width: 64, height: 64)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel(player.isPlaying ? "Pausar" : "Reproducir")

            Button {
                player.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 44, height: 44)
            }
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Detener")
        }
        .buttonStyle(PressableButtonStyle())
        .foregroundStyle(Color.white)
    }

    private func badges(_ station: Station) -> some View {
        HStack(spacing: 6) {
            InfoCard(title: "Códec", value: station.codec ?? "—")
            InfoCard(title: "Bitrate", value: station.bitrate.map { "\($0) kbps" } ?? "—")
            InfoCard(title: "País", value: station.countryCode ?? "—")
            InfoCard(title: "Idioma", value: station.language?.capitalized ?? "—")
        }
    }
}

/// Tarjeta pequeña con un dato del stream.
private struct InfoCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.6))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 2)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.12))
        )
    }
}

/// Degradado propio de cada emisora: el tono sale de su identificador, así que siempre es el mismo.
private struct NowPlayingBackground: View {
    let seed: String

    private var hue: Double {
        let sum = seed.unicodeScalars.reduce(0) { ($0 * 31 + Int($1.value)) % 360 }
        return Double(sum) / 360
    }

    var body: some View {
        LinearGradient(
            colors: [
                Color(hue: hue, saturation: 0.75, brightness: 0.6),
                Color(hue: (hue + 0.06).truncatingRemainder(dividingBy: 1), saturation: 0.8, brightness: 0.35),
                Color(hue: hue, saturation: 0.7, brightness: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(Color.black.opacity(0.15))
        .ignoresSafeArea()
    }
}
