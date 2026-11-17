// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var player: PlayerService

    var body: some View {
        Group {
            if favorites.stations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star").font(.largeTitle).foregroundStyle(.secondary)
                    Text("Aún no tienes favoritos").font(.headline)
                    Text("Toca la estrella en el reproductor para guardar una emisora.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(favorites.stations) { station in
                        Button { player.play(station) } label: { StationRow(station: station) }
                            .buttonStyle(.plain)
                    }
                    .onDelete { favorites.remove(at: $0) }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Favoritos")
    }
}
