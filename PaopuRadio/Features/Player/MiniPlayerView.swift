// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import SwiftUI

/// Contenido del mini reproductor, sin fondo: logo, nombre, estado y reproducir/pausa.
struct MiniPlayerContent: View {
    @EnvironmentObject private var player: PlayerService

    var body: some View {
        HStack(spacing: 12) {
            StationArtwork(station: player.current, cornerRadius: 5)
                .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 1) {
                Text(player.current?.name ?? "No se está reproduciendo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(player.current == nil ? Color.secondary : Color.primary)
                    .lineLimit(1)
                if player.current != nil {
                    Text(player.state.label).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer(minLength: 0)

            Button {
                player.toggle()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 22))
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(PressableButtonStyle())
            .accessibilityLabel(player.isPlaying ? "Pausar" : "Reproducir")
        }
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 12)
        .disabled(player.current == nil)
        .contentShape(Rectangle())
        .onTapGesture {
            if player.current != nil { player.showNowPlaying = true }
        }
    }
}

/// Cápsula propia para iOS 16–25: material translúcido sobre la barra de pestañas.
struct MiniPlayerView: View {
    @EnvironmentObject private var player: PlayerService

    var body: some View {
        if player.current != nil {
            MiniPlayerContent()
                .frame(height: 48)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
    }
}

enum MiniPlayerStyle {
    /// A partir de iOS 26 el mini reproductor es el accesorio inferior de la barra de pestañas
    /// (`tabViewBottomAccessory`), con el cristal del sistema. Antes se dibuja una cápsula propia.
    static var usesSystemAccessory: Bool {
        #if compiler(>=6.2)
        if #available(iOS 26, *) { return true }
        #endif
        return false
    }
}

/// Coloca el mini reproductor como accesorio de la barra de pestañas (iOS 26 o superior).
struct MiniPlayerAccessory: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            content.tabViewBottomAccessory { MiniPlayerContent() }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

/// Solo con la cápsula propia: la reserva por encima de la barra de pestañas, de modo que
/// las listas no queden tapadas.
struct MiniPlayerInset: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if MiniPlayerStyle.usesSystemAccessory {
            content
        } else {
            content.safeAreaInset(edge: .bottom, spacing: 0) { MiniPlayerView() }
        }
    }
}

extension View {
    func miniPlayerAccessory() -> some View { modifier(MiniPlayerAccessory()) }
    func miniPlayerInset() -> some View { modifier(MiniPlayerInset()) }
}
