// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import SwiftUI

/// Pantalla de inicio de Explorar: dos tarjetas, Manual (añadir una emisora propia) y
/// Descubrir (el directorio completo).
struct ExploreView: View {
    @State private var showManual = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                Button { showManual = true } label: {
                    ExploreCard(
                        title: "Manual",
                        subtitle: "Añadir por URL",
                        symbol: "plus.circle.fill",
                        tint: .green
                    )
                }
                .buttonStyle(PressableButtonStyle())

                NavigationLink {
                    BrowseView()
                } label: {
                    ExploreCard(
                        title: "Descubrir",
                        subtitle: "Emisoras del mundo",
                        symbol: "globe.europe.africa.fill",
                        tint: .blue
                    )
                }
                .buttonStyle(PressableButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .navigationTitle("Explorar")
        .sheet(isPresented: $showManual) {
            StationFormView(mode: .create)
        }
    }
}

/// Tarjeta cuadrada con icono de color arriba y título y subtítulo abajo.
private struct ExploreCard: View {
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: symbol)
                .font(.system(size: 28))
                .foregroundStyle(tint)
            Spacer(minLength: 16)
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.primary)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(Color.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
