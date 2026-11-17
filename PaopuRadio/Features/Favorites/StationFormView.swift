// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import PhotosUI
import SwiftUI

/// Formulario para editar el nombre y la carátula de una favorita, o para añadir una emisora propia.
struct StationFormView: View {
    enum Mode {
        case edit(Station)
        case create
    }

    let mode: Mode

    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var player: PlayerService
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var streamText = ""
    @State private var iconChange: IconChange = .keep
    @State private var photo: PhotosPickerItem?
    @State private var imageURLText = ""
    @State private var isLoadingImage = false
    @State private var imageError: String?

    init(mode: Mode) {
        self.mode = mode
        if case .edit(let station) = mode {
            _name = State(initialValue: station.displayName)
        } else {
            _name = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                iconSection
            }
            .navigationTitle(isCreating ? "Nueva emisora" : "Editar emisora")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") { save() }.disabled(!canSave)
                }
            }
            .task(id: photo) { await loadPhoto() }
        }
    }

    // MARK: - Secciones

    private var nameSection: some View {
        Section {
            TextField("Nombre", text: $name)
            if isCreating {
                TextField("URL del stream (https://…)", text: $streamText)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        } footer: {
            if !isCreating {
                Text("Déjalo vacío para volver al nombre original.")
            }
        }
    }

    private var iconSection: some View {
        Section("Carátula") {
            HStack(spacing: 16) {
                StationArtwork(station: previewStation, image: previewImage, cornerRadius: 12)
                    .frame(width: 72, height: 72)
                PhotosPicker("Elegir de la galería", selection: $photo, matching: .images)
            }

            HStack {
                TextField("O pega la URL de una imagen", text: $imageURLText)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if isLoadingImage {
                    ProgressView()
                } else {
                    Button("Usar") { Task { await loadFromURL() } }
                        .disabled(imageURLText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            if let imageError {
                Text(imageError).font(.footnote).foregroundStyle(.red)
            }
            if hasCustomIcon {
                Button("Quitar carátula personalizada", role: .destructive) { removeIcon() }
            }
        }
    }

    // MARK: - Estado

    private var isCreating: Bool {
        if case .create = mode { return true }
        return false
    }

    private var editedStation: Station? {
        if case .edit(let station) = mode { return station }
        return nil
    }

    /// La emisora tal como se verá con los cambios pendientes.
    private var previewStation: Station? {
        guard var station = editedStation else { return nil }
        if case .remove = iconChange { station.customIconFile = nil }
        return station
    }

    private var previewImage: UIImage? {
        if case .set(let image) = iconChange { return image }
        return nil
    }

    private var hasCustomIcon: Bool {
        if case .set = iconChange { return true }
        if case .remove = iconChange { return false }
        return editedStation?.customIconFile != nil
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var streamURL: URL? {
        let text = streamText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: text), url.host != nil,
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https"
        else { return nil }
        return url
    }

    private var canSave: Bool {
        isCreating ? (!trimmedName.isEmpty && streamURL != nil) : true
    }

    // MARK: - Acciones

    private func removeIcon() {
        photo = nil
        imageError = nil
        iconChange = editedStation?.customIconFile != nil ? .remove : .keep
    }

    private func loadPhoto() async {
        guard let photo else { return }
        imageError = nil
        guard let data = try? await photo.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else {
            imageError = "No se pudo leer la imagen."
            return
        }
        iconChange = .set(image)
    }

    private func loadFromURL() async {
        let text = imageURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: text), let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            imageError = "La dirección de la imagen no es válida."
            return
        }
        isLoadingImage = true
        imageError = nil
        defer { isLoadingImage = false }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                imageError = "La dirección no contiene una imagen."
                return
            }
            photo = nil
            imageURLText = ""
            iconChange = .set(image)
        } catch {
            imageError = "No se pudo descargar la imagen (usa una dirección https)."
        }
    }

    private func save() {
        switch mode {
        case .edit(let station):
            let updated = favorites.edit(station, name: name, icon: iconChange)
            player.refresh(updated)
        case .create:
            guard let url = streamURL else { return }
            let station = Station(
                id: "manual-\(UUID().uuidString)",
                name: trimmedName,
                streamURL: url,
                faviconURL: nil,
                tags: [],
                countryCode: nil,
                language: nil,
                codec: nil,
                bitrate: nil
            )
            favorites.add(station)
            favorites.edit(station, name: trimmedName, icon: iconChange)
        }
        dismiss()
    }
}
