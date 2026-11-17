// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import Foundation
import os
import UIKit

/// Qué hacer con el icono de una emisora al guardar los cambios.
enum IconChange {
    case keep
    case remove
    case set(UIImage)
}

/// Emisoras favoritas, guardadas en un JSON dentro de Application Support.
/// También guarda el nombre y el icono que el usuario les haya puesto.
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

    /// La versión guardada (con sus cambios) si es favorita; si no, la misma emisora.
    func resolved(_ station: Station) -> Station {
        stations.first { $0.id == station.id } ?? station
    }

    func toggle(_ station: Station) {
        if let index = stations.firstIndex(where: { $0.id == station.id }) {
            StationIconStore.delete(stations[index].customIconFile)
            stations.remove(at: index)
        } else {
            stations.insert(station, at: 0)
        }
        save()
    }

    /// Añade una emisora a favoritos (si ya estaba, no hace nada).
    func add(_ station: Station) {
        guard !isFavorite(station) else { return }
        stations.insert(station, at: 0)
        save()
    }

    func remove(at offsets: IndexSet) {
        for index in offsets { StationIconStore.delete(stations[index].customIconFile) }
        stations.remove(atOffsets: offsets)
        save()
    }

    /// Cambia el nombre y/o el icono de una favorita y devuelve la emisora ya actualizada.
    /// Un nombre vacío (o igual al original) quita el nombre personalizado.
    @discardableResult
    func edit(_ station: Station, name: String, icon: IconChange) -> Station {
        var updated = resolved(station)
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.customName = (trimmed.isEmpty || trimmed == updated.name) ? nil : trimmed

        switch icon {
        case .keep:
            break
        case .remove:
            StationIconStore.delete(updated.customIconFile)
            updated.customIconFile = nil
        case .set(let image):
            if let file = StationIconStore.save(image, for: updated.id) {
                StationIconStore.delete(updated.customIconFile)
                updated.customIconFile = file
            }
        }

        if let index = stations.firstIndex(where: { $0.id == updated.id }) {
            stations[index] = updated
            save()
        }
        return updated
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
