// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import Foundation

/// Filtros de búsqueda en el directorio de emisoras.
struct StationQuery: Sendable, Equatable {
    var name = ""
    var countryCode: String?
    var language: String?
    var tag: String?
}

protocol RadioDirectoryService: Sendable {
    /// Devuelve una página de emisoras ordenadas por popularidad (clics).
    func search(_ query: StationQuery, limit: Int, offset: Int) async throws -> [Station]
}

/// Respuesta cruda de Radio Browser; se convierte a `Station` descartando entradas inválidas.
struct StationDTO: Decodable, Sendable {
    let id: String
    let name: String
    let streamURL: String?
    let favicon: String?
    let tags: String?
    let countryCode: String?
    let language: String?
    let codec: String?
    let bitrate: Int?
    let lastCheckOK: Int?

    enum CodingKeys: String, CodingKey {
        case id = "stationuuid"
        case name
        case streamURL = "url_resolved"
        case favicon
        case tags
        case countryCode = "countrycode"
        case language
        case codec
        case bitrate
        case lastCheckOK = "lastcheckok"
    }

    /// `nil` si la emisora está caída, no tiene nombre o su URL no es HTTP(S).
    func toStation() -> Station? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard lastCheckOK != 0, !trimmedName.isEmpty,
              let raw = streamURL, let url = URL(string: raw),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https"
        else { return nil }

        return Station(
            id: id,
            name: trimmedName,
            streamURL: url,
            faviconURL: favicon.flatMap { $0.isEmpty ? nil : URL(string: $0) },
            tags: (tags ?? "")
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty },
            countryCode: countryCode.flatMap { $0.isEmpty ? nil : $0 },
            language: language.flatMap { $0.isEmpty ? nil : $0 },
            codec: codec.flatMap { $0.isEmpty ? nil : $0 },
            bitrate: bitrate.flatMap { $0 > 0 ? $0 : nil }
        )
    }
}

/// Cliente de Radio Browser (`radio-browser.info`). Descubre servidores y reintenta con otro si uno falla.
actor RadioBrowserService: RadioDirectoryService {
    private struct ServerDTO: Decodable { let name: String }

    private static let fallbackHosts = [
        "de1.api.radio-browser.info", "de2.api.radio-browser.info", "fi1.api.radio-browser.info"
    ]
    private static let userAgent = "PaopuRadio/0.1"

    private let session: URLSession
    private var hosts: [String]?

    init(session: URLSession = .shared) {
        self.session = session
    }

    func search(_ query: StationQuery, limit: Int, offset: Int) async throws -> [Station] {
        var items = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "order", value: "clickcount"),
            URLQueryItem(name: "reverse", value: "true"),
            URLQueryItem(name: "hidebroken", value: "true")
        ]
        if !query.name.isEmpty { items.append(URLQueryItem(name: "name", value: query.name)) }
        if let code = query.countryCode { items.append(URLQueryItem(name: "countrycode", value: code)) }
        if let language = query.language { items.append(URLQueryItem(name: "language", value: language)) }
        if let tag = query.tag { items.append(URLQueryItem(name: "tag", value: tag)) }

        var lastError: Error = URLError(.cannotFindHost)
        for host in await availableHosts() {
            try Task.checkCancellation()
            var components = URLComponents()
            components.scheme = "https"
            components.host = host
            components.path = "/json/stations/search"
            components.queryItems = items
            guard let url = components.url else { continue }

            var request = URLRequest(url: url, timeoutInterval: 10)
            request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
            do {
                let (data, response) = try await session.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
                return try JSONDecoder().decode([StationDTO].self, from: data).compactMap { $0.toStation() }
            } catch let error as URLError where error.code == .cancelled {
                throw error
            } catch {
                lastError = error // probar con el siguiente servidor
            }
        }
        throw lastError
    }

    /// Lista de servidores oficial; si no se puede obtener, usa una lista fija.
    private func availableHosts() async -> [String] {
        if let hosts { return hosts }
        var found = Self.fallbackHosts
        if let url = URL(string: "https://all.api.radio-browser.info/json/servers"),
           let (data, _) = try? await session.data(from: url),
           let list = try? JSONDecoder().decode([ServerDTO].self, from: data), !list.isEmpty {
            found = list.map(\.name).shuffled()
        }
        hosts = found
        return found
    }
}
