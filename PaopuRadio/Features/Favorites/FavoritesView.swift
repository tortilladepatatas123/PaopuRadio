// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var player: PlayerService
    @State private var editing: Station?

    var body: some View {
        Group {
            if favorites.stations.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star").font(.largeTitle).foregroundStyle(.secondary)
                    Text("Aún no tienes favoritos").font(.headline)
                    Text("Toca la estrella en el reproductor o añade una emisora desde Explorar.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(32)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                list
            }
        }
        .navigationTitle("Favoritos")
        .sheet(item: $editing) { station in
            StationFormView(mode: .edit(station))
                .environmentObject(favorites)
                .environmentObject(player)
        }
    }

    private var list: some View {
        List {
            ForEach(favorites.stations) { station in
                Button { player.play(station) } label: { StationRow(station: station) }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .leading) {
                        Button { editing = station } label: { Label("Editar", systemImage: "pencil") }
                            .tint(.orange)
                    }
                    .contextMenu {
                        Button { editing = station } label: { Label("Editar", systemImage: "pencil") }
                    }
            }
            .onDelete { favorites.remove(at: $0) }
        }
        .listStyle(.plain)
    }
}
