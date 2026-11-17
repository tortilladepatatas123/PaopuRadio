// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import os
import UIKit

/// Iconos personalizados de las emisoras, guardados como PNG en Application Support.
@MainActor
enum StationIconStore {
    private static let cache = NSCache<NSString, UIImage>()
    private static let logger = Logger(subsystem: "com.paopu.app", category: "icons")

    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("StationIcons", isDirectory: true)
    }

    static func image(named file: String?) -> UIImage? {
        guard let file else { return nil }
        if let cached = cache.object(forKey: file as NSString) { return cached }
        guard let image = UIImage(contentsOfFile: directory.appendingPathComponent(file).path) else { return nil }
        cache.setObject(image, forKey: file as NSString)
        return image
    }

    /// Guarda la imagen (reducida a 512 px como máximo) y devuelve el nombre del archivo.
    /// Cada guardado usa un nombre nuevo, así la caché nunca sirve una imagen antigua.
    static func save(_ image: UIImage, for stationID: String) -> String? {
        let longest = max(image.size.width, image.size.height)
        guard longest > 0 else { return nil }
        let scale = min(1, 512 / longest)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let data = UIGraphicsImageRenderer(size: size, format: format)
            .image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
            .pngData()
        guard let data else { return nil }

        let safeID = stationID.filter { $0.isLetter || $0.isNumber || $0 == "-" }
        let file = "\(safeID)-\(UUID().uuidString.prefix(8)).png"
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: directory.appendingPathComponent(file), options: .atomic)
            return file
        } catch {
            logger.error("No se pudo guardar el icono: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    static func delete(_ file: String?) {
        guard let file else { return }
        cache.removeObject(forKey: file as NSString)
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(file))
    }
}
