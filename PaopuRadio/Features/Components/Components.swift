// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import AVKit
import SwiftUI

/// Logo de la emisora con un icono propio mientras carga o si no tiene.
struct StationArtwork: View {
    let station: Station?
    var cornerRadius: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let inset = min(geo.size.width, geo.size.height) * 0.12
            ZStack {
                Rectangle().fill(Color(.secondarySystemFill))
                AsyncImage(url: station?.faviconURL) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit().padding(inset)
                    } else {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.secondary)
                            .padding(min(geo.size.width, geo.size.height) * 0.28)
                    }
                }
            }
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
                Text(station.name).font(.headline).lineLimit(1)
                Text(station.detailText).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

extension Station {
    /// País, códec y bitrate en una línea.
    var detailText: String {
        [countryCode, codec, bitrate.map { "\($0) kbps" }]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}

/// Botón que se encoge un poco al pulsarlo.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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
