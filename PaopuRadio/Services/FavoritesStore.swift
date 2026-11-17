// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import Foundation
import os

/// Emisoras favoritas, guardadas en un JSON dentro de Application Support.
@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var stations: [Station] = []

    private let fileURL: URL
    private let logger = Logger(subsystem: "com.paopu.app", category: "favorites")

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        fileURL = base.appendingPathComponent("favorites.json")
        load()
    }

    func isFavorite(_ station: Station) -> Bool {
        stations.contains { $0.id == station.id }
    }

    func toggle(_ station: Station) {
        if let index = stations.firstIndex(where: { $0.id == station.id }) {
            stations.remove(at: index)
        } else {
            stations.insert(station, at: 0)
        }
        save()
    }

    func remove(at offsets: IndexSet) {
        stations.remove(atOffsets: offsets)
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            stations = try JSONDecoder().decode([Station].self, from: data)
        } catch {
            logger.error("No se pudieron leer los favoritos: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try JSONEncoder().encode(stations).write(to: fileURL, options: .atomic)
        } catch {
            logger.error("No se pudieron guardar los favoritos: \(error.localizedDescription, privacy: .public)")
        }
    }
}
