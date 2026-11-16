// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            BrowseView()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MiniPlayerView()
        }
    }
}
