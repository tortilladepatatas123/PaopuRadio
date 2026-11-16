// Paopu Radio — radio por internet para iPhone.
// Copyright (C) 2026 Paopu Radio contributors.
// Licencia GPL-3.0-or-later. Consulta el archivo LICENSE.

import XCTest
@testable import PaopuRadio

final class StationDTOTests: XCTestCase {
    private func decode(_ json: String) throws -> StationDTO {
        try JSONDecoder().decode(StationDTO.self, from: Data(json.utf8))
    }

    func testMapsValidStation() throws {
        let dto = try decode("""
        {"stationuuid":"abc","name":" Radio Uno ","url_resolved":"https://example.com/live.mp3",
         "favicon":"","tags":"pop, rock,","countrycode":"ES","codec":"MP3","bitrate":128,"lastcheckok":1}
        """)
        let station = try XCTUnwrap(dto.toStation())
        XCTAssertEqual(station.name, "Radio Uno")
        XCTAssertNil(station.faviconURL)
        XCTAssertEqual(station.tags, ["pop", "rock"])
        XCTAssertEqual(station.bitrate, 128)
    }

    func testDiscardsBrokenStation() throws {
        let dto = try decode(#"{"stationuuid":"a","name":"X","url_resolved":"https://e.com/s","lastcheckok":0}"#)
        XCTAssertNil(dto.toStation())
    }

    func testDiscardsNonHTTPURL() throws {
        let dto = try decode(#"{"stationuuid":"a","name":"X","url_resolved":"rtsp://e.com/s","lastcheckok":1}"#)
        XCTAssertNil(dto.toStation())
    }
}
