// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import AVKit
import SwiftUI

/// Carátula: la que envía la emisora en los metadatos o, si no hay, su logo (con un icono propio mientras carga).
struct StationArtwork: View {
    let station: Station?
    var image: UIImage?
    var cornerRadius: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                Rectangle().fill(Color(.secondarySystemFill))
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    AsyncImage(url: station?.faviconURL) { phase in
                        if let loaded = phase.image {
                            loaded.resizable().scaledToFit().padding(side * 0.12)
                        } else {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.secondary)
                                .padding(side * 0.28)
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Fila de emisora: logo, nombre y datos técnicos.
struct StationRow: View {
    let station: Station

    var body: some View {
        HStack(spacing: 12) {
            StationArtwork(station: station)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                MarqueeText(text: station.name, font: .headline)
                MarqueeText(text: station.detailText, font: .subheadline, color: .secondary)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

extension Station {
    /// País, códec y bitrate en una línea, separados por viñetas.
    var detailText: String {
        [countryCode, codec, bitrate.map { "\($0) kbps" }]
            .compactMap { $0 }
            .joined(separator: " • ")
    }
}

/// Icono de reproducir/pausar con transición animada: uno gira y se encoge mientras el otro entra.
struct PlayPauseIcon: View {
    let isPlaying: Bool
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            Image(systemName: "pause.fill")
                .scaleEffect(isPlaying ? 1 : 0.4)
                .rotationEffect(.degrees(isPlaying ? 0 : -90))
                .opacity(isPlaying ? 1 : 0)

            Image(systemName: "play.fill")
                .scaleEffect(isPlaying ? 0.4 : 1)
                .rotationEffect(.degrees(isPlaying ? 90 : 0))
                .opacity(isPlaying ? 0 : 1)
        }
        .font(.system(size: size))
        .animation(.spring(response: 0.32, dampingFraction: 0.7), value: isPlaying)
    }
}

/// Botón sin estilo propio que se encoge un poco al pulsarlo.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Selector de salida de audio del sistema (AirPlay, Bluetooth…).
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = .white
        view.activeTintColor = .white
        view.prioritizesVideoDevices = false
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}
