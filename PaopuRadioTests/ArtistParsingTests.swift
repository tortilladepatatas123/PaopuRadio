// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import XCTest
@testable import PaopuRadio

final class ArtistParsingTests: XCTestCase {
    func testSplitsGluedArtists() {
        XCTAssertEqual(MetadataReceiver.normalizeArtists("Artista A,Artista B"), "Artista A, Artista B")
    }

    func testTrimsExtraSpacesAndSemicolons() {
        XCTAssertEqual(MetadataReceiver.normalizeArtists(" A , B;C ,"), "A, B, C")
    }

    func testEmptyArtistIsNil() {
        XCTAssertNil(MetadataReceiver.normalizeArtists(" , ; "))
    }

    func testParseSeparatesArtistsAndTitle() {
        let parsed = MetadataReceiver.parse("Artista A,Artista B - Tema")
        XCTAssertEqual(parsed.artist, "Artista A, Artista B")
        XCTAssertEqual(parsed.title, "Tema")
    }

    func testParseWithoutSeparatorKeepsWholeTextAsTitle() {
        let parsed = MetadataReceiver.parse("Solo título")
        XCTAssertEqual(parsed.title, "Solo título")
        XCTAssertNil(parsed.artist)
    }
}
