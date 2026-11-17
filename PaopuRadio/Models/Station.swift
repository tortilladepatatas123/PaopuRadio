// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import Foundation

/// Emisora de radio tal y como la usa la app (y como se guarda en favoritos/recientes).
struct Station: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var name: String
    var streamURL: URL
    var faviconURL: URL?
    var tags: [String]
    var countryCode: String?
    var language: String?
    var codec: String?
    var bitrate: Int?
    /// Nombre elegido por el usuario (solo en favoritas).
    var customName: String?
    /// Archivo del icono elegido por el usuario (solo en favoritas).
    var customIconFile: String?

    /// Nombre que se muestra, dentro y fuera de la app.
    var displayName: String { customName ?? name }
}
