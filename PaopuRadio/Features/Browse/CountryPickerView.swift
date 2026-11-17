// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import SwiftUI

struct Country: Identifiable, Sendable {
    let code: String
    let name: String

    var id: String { code }

    /// Bandera en emoji a partir del código ISO.
    var flag: String {
        code.unicodeScalars
            .compactMap { UnicodeScalar(127_397 + $0.value) }
            .map { String($0) }
            .joined()
    }

    /// Todos los países, con su nombre en el idioma del sistema y ordenados alfabéticamente.
    static let all: [Country] = Locale.Region.isoRegions
        .map(\.identifier)
        .filter { $0.count == 2 && $0.allSatisfy(\.isLetter) }
        .compactMap { code in
            Locale.current.localizedString(forRegionCode: code).map { Country(code: code, name: $0) }
        }
        .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
}

/// Hoja para elegir el país por el que filtrar. Una cadena vacía significa "todos".
struct CountryPickerView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private var countries: [Country] {
        guard !search.isEmpty else { return Country.all }
        return Country.all.filter { $0.name.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                if search.isEmpty {
                    row(title: "Todos los países", flag: "🌍", code: "")
                }
                ForEach(countries) { country in
                    row(title: country.name, flag: country.flag, code: country.code)
                }
            }
            .listStyle(.plain)
            .navigationTitle("País")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Buscar país")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private func row(title: String, flag: String, code: String) -> some View {
        Button {
            selection = code
            dismiss()
        } label: {
            HStack {
                Text(flag)
                Text(title)
                Spacer()
                if selection == code {
                    Image(systemName: "checkmark").foregroundStyle(Color.accentColor)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
