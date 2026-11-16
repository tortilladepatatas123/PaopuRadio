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

private struct StationRow: View {
    let station: Station

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: station.faviconURL) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundStyle(.secondary)
            }
            .frame(width: 44, height: 44)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(station.name).font(.headline).lineLimit(1)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        [station.countryCode, station.codec, station.bitrate.map { "\($0) kbps" }]
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}
