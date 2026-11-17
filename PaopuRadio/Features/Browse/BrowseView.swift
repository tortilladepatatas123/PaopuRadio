// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import SwiftUI

struct BrowseView: View {
    @StateObject private var viewModel = BrowseViewModel()
    @EnvironmentObject private var player: PlayerService

    var body: some View {
        List {
            ForEach(viewModel.stations) { station in
                Button { player.play(station) } label: { StationRow(station: station) }
                    .buttonStyle(.plain)
                    .onAppear {
                        if station.id == viewModel.stations.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
            }
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity)
            }
            if let message = viewModel.errorMessage {
                VStack(spacing: 8) {
                    Text(message).foregroundStyle(.secondary)
                    Button("Reintentar") { Task { await viewModel.loadMore() } }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Explorar")
        .searchable(text: $viewModel.query, prompt: "Buscar emisoras")
        .task(id: viewModel.query) {
            // Espera breve al teclear; la carga inicial (búsqueda vacía) es inmediata.
            if !viewModel.query.isEmpty {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
            }
            await viewModel.reload()
        }
    }
}
