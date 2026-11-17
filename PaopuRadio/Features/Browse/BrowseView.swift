// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import SwiftUI

struct BrowseView: View {
    @StateObject private var viewModel = BrowseViewModel()
    @EnvironmentObject private var player: PlayerService
    @EnvironmentObject private var favorites: FavoritesStore
    /// País elegido; se guarda y se recupera al abrir la app. Vacío = todos.
    @AppStorage("countryFilter") private var country = ""
    @State private var showCountries = false

    private struct SearchKey: Equatable {
        let text: String
        let country: String
    }

    var body: some View {
        List {
            ForEach(viewModel.stations) { station in
                Button { player.play(favorites.resolved(station)) } label: { StationRow(station: station) }
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
        .navigationTitle("Descubrir")
        .searchable(text: $viewModel.query, prompt: "Buscar emisoras")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showCountries = true } label: {
                    Label(country.isEmpty ? "País" : country, systemImage: "globe")
                }
            }
        }
        .sheet(isPresented: $showCountries) {
            CountryPickerView(selection: $country)
        }
        .task(id: SearchKey(text: viewModel.query, country: country)) {
            // Espera breve al teclear; la carga inicial (búsqueda vacía) es inmediata.
            if !viewModel.query.isEmpty {
                try? await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
            }
            await viewModel.reload(country: country)
        }
    }
}
