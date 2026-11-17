// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var player: PlayerService
    @EnvironmentObject private var favorites: FavoritesStore

    var body: some View {
        TabView {
            NavigationStack { FavoritesView() }
                .miniPlayerInset()
                .tabItem { Label("Favoritos", systemImage: "star") }
            NavigationStack { ExploreView() }
                .miniPlayerInset()
                .tabItem { Label("Explorar", systemImage: "dot.radiowaves.left.and.right") }
        }
        .miniPlayerAccessory()
        .sheet(isPresented: $player.showNowPlaying) {
            NowPlayingView()
                .environmentObject(player)
                .environmentObject(favorites)
                .presentationDragIndicator(.visible)
        }
    }
}
