# Sudoku

Un Sudoku nativo para Mac, sin anuncios, escrito en SwiftUI.

Nació como una forma práctica de aprender Swift y los frameworks de Apple, así que el código
prefiere APIs modernas e idiomáticas (`@Observable`, Swift Testing, concurrencia de Swift,
SwiftData) y explica *por qué* hace las cosas como las hace.

*[Read in English](README.md)*

## Descargar

Descarga `Sudoku.zip` desde la [última versión](https://github.com/vg0904/Sudoku/releases/latest),
descomprímelo y mueve **Sudoku** a tu carpeta Aplicaciones.

### Abrir la app por primera vez

La app no está notarizada por Apple ([aquí explico por qué](#sobre-este-proyecto)), así que la
primera vez que la abras macOS dirá que no puede verificar al desarrollador. Solo hay que
permitirla una vez:

1. Abre **Sudoku**. Cuando macOS muestre el aviso, pulsa **OK**.
2. Abre **Ajustes del Sistema → Privacidad y seguridad**.
3. Baja hasta la sección **Seguridad**. Junto al mensaje sobre Sudoku, pulsa **Abrir igualmente** y
   confirma con tu contraseña o Touch ID.
4. Pulsa **Abrir** en el cuadro de diálogo que aparece.

A partir de entonces se abre como cualquier otra app.

<details>
<summary>¿Prefieres la Terminal?</summary>

Esto quita la marca de cuarentena que macOS pone a los archivos descargados:

```sh
xattr -dr com.apple.quarantine /Applications/Sudoku.app
```

</details>

Si prefieres no abrir una app sin notarizar, puedes [compilarla tú](#primeros-pasos) desde el
código fuente en unos minutos.

## Funcionalidades

- **Tableros aleatorios con solución única** en tres niveles de dificultad, generados fuera del
  hilo principal para que la ventana nunca se congele.
- **Vidas** (de 1 a 5 o ilimitadas): cada error cuesta un corazón. Las respuestas correctas quedan
  fijas y solo se pueden borrar los errores, así que una tecla pulsada por accidente no cuesta nada.
- **Ayudas visuales**: resaltar la fila, la columna y el recuadro seleccionados; hacer brillar los
  números iguales; recuadros 3×3 alternados; una selección que se desliza entre celdas.
- **Progreso en el teclado numérico**: cada tecla se va llenando al colocar su número, y al
  completar los nueve celebra y se convierte en una palomita.
- **Celebraciones** al completar una fila, columna, recuadro o número, con el estilo que elijas
  (Onda, Volteo, Salto, Destello o Ninguna) y una vista previa en los Ajustes. Confeti al ganar.
- **Récords estilo arcade**: un top 10 por dificultad guardado con SwiftData. Escribes tu nombre al
  hacer récord; el último se recuerda y los anteriores están a un clic. Cada récord muestra el
  tiempo, las vidas usadas, los errores y la fecha.
- **Tiempos justos**: pausa con ⌘P (el tablero se oculta mientras tanto) y pausa automática al
  cambiar de app.
- **La partida se guarda**: cierra la app cuando quieras y sigue donde lo dejaste la próxima vez que
  la abras.
- **Temas de color**: por defecto sigue el color de acento del Mac, o elige uno de ocho colores
  ajustados para leerse bien en modo claro y oscuro.
- **Accesibilidad**: VoiceOver lee el número y el estado de cada celda, y también puede decir su
  fila y columna. Todas las animaciones respetan "Reducir movimiento", además de un ajuste propio,
  "Reducir animaciones".
- **Localizado** en inglés y español, con cambio de idioma en los Ajustes sin reiniciar.
- **Nativo de Mac**: barra de herramientas con Liquid Glass, comandos de menú con atajos de
  teclado, ventana de Ajustes y una ventana aparte para los Récords.

### Atajos de teclado

| Atajo | Acción |
|---|---|
| 1–9 | Escribir un número en la celda seleccionada |
| Flechas | Mover la selección |
| ⌫ / ⌦ | Borrar un número incorrecto |
| ⌘N | Nueva partida |
| ⌘R | Borrar el tablero (pide confirmación) |
| ⌘P | Pausar / reanudar |
| ⌘L | Abrir la ventana de Récords |
| ⌘, | Ajustes |

## Requisitos

- macOS 27 o posterior
- Xcode 27 o posterior

El proyecto no tiene dependencias externas.

## Primeros pasos

1. Clona el repositorio:

   ```sh
   git clone https://github.com/vg0904/Sudoku.git
   ```

2. Abre `Sudoku.xcodeproj` en Xcode.
3. **Configura la firma.** El proyecto viene con el equipo de desarrollo del autor. En el editor
   del proyecto, selecciona el target **Sudoku** → **Signing & Capabilities** y elige tu propio
   equipo (sirve un equipo personal gratuito). Si Xcode dice que el identificador del bundle ya está
   en uso, cámbialo por uno único, como `com.tunombre.Sudoku`.

   Por favor, no incluyas estos cambios de firma en tus pull requests.
4. Pulsa **⌘R** para compilar y ejecutar.

## Ejecutar las pruebas

La lógica está cubierta por más de 200 pruebas escritas con
[Swift Testing](https://developer.apple.com/documentation/testing).

- En Xcode: **⌘U**, o abre el navegador de pruebas (**⌘6**).
- Desde la terminal:

  ```sh
  xcodebuild test -project Sudoku.xcodeproj -scheme Sudoku -destination 'platform=macOS'
  ```

Las pruebas nunca tocan tus datos reales: los ajustes usan un `UserDefaults` aislado y los récords
una base de datos de SwiftData en memoria.

## Estructura del proyecto

```
Sudoku/
├── Model/      Lógica pura del juego: la cuadrícula, el generador, la dificultad, los récords.
├── Game/       El estado de la partida (`SudokuGame`), el reloj y los avisos de celebración.
├── Settings/   Los ajustes (guardados en UserDefaults) y la ventana de Ajustes.
├── Views/      Vistas de SwiftUI: tablero, celdas, teclado, superposiciones, confeti, récords.
└── SudokuApp.swift   Las escenas (juego, Récords, Ajustes) y los comandos de menú.
SudokuTests/    Suites de Swift Testing, un archivo por área.
```

Para ver cómo encajan las piezas, y las decisiones poco evidentes detrás de ellas, consulta
**[ARCHITECTURE.md](docs/ARCHITECTURE.md)** (en inglés).

## Sobre este proyecto

Soy estudiante, y este Sudoku es un proyecto que hago por hobby. Lo construí para aprender Swift y
los frameworks de Apple a fondo, haciendo algo que de verdad quería usar: un Sudoku limpio para mi
Mac, sin anuncios ni rastreo. Lo comparto para que otras personas puedan jugarlo, leer el código,
aprender de él y ayudar a mejorarlo.

No gano dinero con él, ni es mi intención. Por eso tampoco está notarizado: la notarización exige
pagar el Apple Developer Program (99 USD al año), algo que no tiene sentido para un proyecto
gratuito hecho para aprender. Todo el código fuente está aquí, así que siempre puedes comprobar qué
hace exactamente la app, o compilarla tú.

## Contribuir

¡Las contribuciones son bienvenidas! Lee primero **[CONTRIBUTING.md](CONTRIBUTING.md)** (en
inglés): explica las convenciones de las que depende el proyecto (aislamiento de actores,
localización, animaciones y pruebas).

Sobre el idioma: **los comentarios del código están en español**, mientras que los identificadores,
las claves de texto y la documentación están en inglés. En las contribuciones se aceptan comentarios
en cualquiera de los dos idiomas.

## Licencia

Sudoku se publica bajo la [licencia MIT](LICENSE).
