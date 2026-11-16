# Paopu Radio

Radio por internet para iPhone: nativa, ligera y privada.

Paopu Radio es una app de código abierto escrita en Swift y SwiftUI, sin dependencias de terceros, sin anuncios y sin analítica. Las emisoras vienen de [Radio Browser](https://www.radio-browser.info), un directorio abierto con decenas de miles de emisoras de todo el mundo.

> **Estado:** en desarrollo temprano (v0.1). Ya puedes explorar, buscar y escuchar emisoras; el resto de funciones están en camino.

## Funciones

**Disponibles**
- Explorar y buscar emisoras, con carga paginada.
- Reproducción con play/pausa y mini reproductor.
- Audio en segundo plano y controles en la pantalla de bloqueo.

**Próximamente**
- Favoritos y recientes.
- Título y artista de lo que suena.
- Temporizador de apagado.
- Reproductor a pantalla completa y AirPlay.
- Filtros por país, idioma y etiqueta.
- Añadir una emisora por URL.

## Requisitos

- iPhone con iOS 16 o superior.
- Una herramienta de sideloading (la app se distribuye sin firmar).

## Instalación

1. Descarga `PaopuRadio.ipa` desde la pestaña [Releases](../../releases).
2. Instálalo con [AltStore](https://altstore.io), [SideStore](https://sidestore.io) o [Sideloadly](https://sideloadly.io).

Como el `.ipa` no está firmado, la herramienta de sideloading lo firmará con tu propio Apple ID. Con una cuenta gratuita, la app caduca a los 7 días y hay que renovarla.

## Privacidad

- No hay cuentas, analítica, publicidad ni rastreadores.
- La app solo se conecta al directorio Radio Browser y a los servidores de las emisoras que reproduces.
- Tus datos se quedan en tu dispositivo.

## Compilar desde el código

Requiere macOS con Xcode 26 y [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
open PaopuRadio.xcodeproj
```

El `.xcodeproj` no se incluye en el repositorio: se genera desde `project.yml`. La integración continua (`.github/workflows/ci.yml`) ejecuta lint, pruebas y empaqueta el `.ipa`.

## Contribuir

Las contribuciones son bienvenidas. Abre un *issue* para comentar una idea o un fallo, o envía un *pull request* con una sola funcionalidad por rama. Los commits siguen [Conventional Commits](https://www.conventionalcommits.org/es/) (`feat:`, `fix:`, `chore:`).

## Aviso

Paopu Radio no es propietaria de las emisoras ni de sus contenidos: solo reproduce los streams públicos que publican sus responsables en Radio Browser.

## Licencia

[GPL-3.0-or-later](LICENSE).
