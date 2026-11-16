# Paopu Radio

Radio por internet para iPhone, nativa, ligera y sin dependencias de terceros.
Swift 6 · SwiftUI · iOS 16+ (compilada con el SDK de iOS 26) · GPL-3.0.

Las emisoras vienen de [Radio Browser](https://www.radio-browser.info), un directorio abierto.

## Instalar el `.ipa`

1. Descarga `PaopuRadio.ipa` desde la pestaña *Releases* (o desde los artefactos de la última ejecución de *Actions*).
2. El archivo no está firmado: instálalo con AltStore, SideStore o Sideloadly.

## Compilar

Requiere macOS con Xcode 26 y [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
open PaopuRadio.xcodeproj
```

El `.xcodeproj` no se versiona: se genera desde `project.yml`. La CI (`.github/workflows/ci.yml`) hace lint, pruebas y el empaquetado del `.ipa`.

## Licencia

GPL-3.0-or-later. Consulta `LICENSE`.
