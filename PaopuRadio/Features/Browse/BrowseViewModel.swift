// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import SwiftUI

@MainActor
final class BrowseViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var stations: [Station] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: any RadioDirectoryService
    private let pageSize = 30
    private var offset = 0
    private var reachedEnd = false
    private var generation = 0

    init(service: any RadioDirectoryService = RadioBrowserService()) {
        self.service = service
    }

    /// Reinicia la lista (p. ej. al cambiar la búsqueda) y carga la primera página.
    func reload() async {
        generation += 1
        offset = 0
        reachedEnd = false
        isLoading = false
        stations = []
        await loadMore()
    }

    /// Carga la siguiente página; ignora respuestas de búsquedas ya obsoletas.
    func loadMore() async {
        guard !isLoading, !reachedEnd else { return }
        let current = generation
        isLoading = true
        errorMessage = nil
        defer { if current == generation { isLoading = false } }

        do {
            let page = try await service.search(StationQuery(name: query), limit: pageSize, offset: offset)
            guard current == generation else { return }
            stations += page
            offset += pageSize
            reachedEnd = page.isEmpty
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            guard current == generation else { return }
            errorMessage = "No se pudieron cargar las emisoras."
        }
    }
}
